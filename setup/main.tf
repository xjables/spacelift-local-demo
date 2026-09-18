terraform {
  required_version = ">= 1.11"

  backend "s3" {
    bucket = "spacelift-local-demo-444839312137-us-west-2-an"
    key    = "setup.tfstate"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Make sure you are authenticated with an admin user for this setup.
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Obviously this bucket needs to be defined a priori, otherwise we couldn't
# stare into its depths.
data "aws_s3_bucket" "state_bucket" {
  bucket = "spacelift-local-demo-444839312137-us-west-2-an"
}

# Rather than use the honor system, we want to enforce exactly which identities
# have access to touch the state, and in what way. We can gate that directly
# with a bucket policy. See the note below if you have already defined a bucket
# policy in another stack.
data "aws_iam_policy_document" "state_bucket" {
  dynamic "statement" {
    for_each = var.spacelift_arn != null ? [1] : []
    content {
      sid     = "spacelift"
      effect  = "Deny"
      actions = ["s3:PutObject"]
      resources = [
        "${data.aws_s3_bucket.state_bucket.arn}/demo.tfstate",
      ]
      not_principals {
        type        = "AWS"
        identifiers = [aws_iam_role.spacelift_admin.arn]
      }
    }
  }

  statement {
    sid     = "denyExceptSpaceliftAndPlanners"
    effect  = "Deny"
    actions = ["s3:GetObject"]
    resources = [
      "${data.aws_s3_bucket.state_bucket.arn}/demo.tfstate",
    ]

    not_principals {
      type        = "AWS"
      identifiers = var.spacelift_arn != null ? [aws_iam_role.spacelift_admin.arn, aws_iam_role.planners.arn] : [aws_iam_role.planners.arn]
    }
  }

  statement {
    sid     = "noDeletes"
    effect  = "Deny"
    actions = ["s3:DeleteObject"]
    resources = [
      "${data.aws_s3_bucket.state_bucket.arn}/demo.tfstate",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

# AWS

# If you define this bucket policy elsewhere (such as where you create your state
# bucket), you cannot redefine it here without destroying the existing policy. In
# that case, you would go to where the bucket policy already exists and hard code
# the roles in the policy above in place. Or -- how I would do it if I wanted it
# to work in production -- I would define all of the roles with access to this
# bucket under role paths, like "/opentofu/admin/" and "/opentofu/read/",
# respectively, and have the bucket policy wildcard on those paths:
#
# > aws:iam:${account_id}:${region}:role/opentofu/admin/* given s3:*
# > aws:iam:${account_id}:${region}:role/opentofu/read/* given s3:Read*
#
# That way if I ever change the names of those roles, I don't have to remember I
# have a hardcoded value somewhere in my codebase.
#
# I am creating this policy here because this is a demo and it easier to set the
# bucket policy where the roles are generated because I have direct access to
# their resource identifiers.
resource "aws_s3_bucket_policy" "state_bucket" {
  bucket = data.aws_s3_bucket.state_bucket.id
  policy = data.aws_iam_policy_document.state_bucket.json
}


# This role will be assumable by identities you want to be able to be able to
# plan from the CLI locally.
resource "aws_iam_role" "planners" {
  name               = "planners"
  assume_role_policy = data.aws_iam_policy_document.planners_assume.json
}

data "aws_iam_policy_document" "planners_assume" {
  statement {
    sid     = "planners"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"
      # This role arn(s) will one that you want your local planning users to be able to assume.
      identifiers = var.local_planner_arns
    }
  }
}

# This is pretty broad read only access. Make sure whichever identities can
# assume this role already have blanket read access to this account, because
# they will after.
data "aws_iam_policy" "readonly" {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy_attachment" "planners" {
  name = "planners"
  # Nonplanners are attached for reasons explained below
  roles      = [aws_iam_role.planners.name, aws_iam_role.non_planner.name]
  policy_arn = data.aws_iam_policy.readonly.arn
}

# An experiment is only as good as it's control. This role will be assumable by
# the same principals as the planner role and have the same read only policy
# attached; however, it will be unable to run a plan against the demo
# configuration as it is absent from the bucket policy.
resource "aws_iam_role" "non_planner" {
  name               = "non-planner"
  assume_role_policy = data.aws_iam_policy_document.planners_assume.json
}

# This role is for demonstration purposes only. In a real environment, it's
# probably best to use a CloudFormation stack in your organization to bootstrap
# this role automatically when an account is vended.
data "aws_iam_policy" "admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "spacelift_assume" {
  statement {
    sid       = "spacelift"
    actions   = ["sts:AssumeRole"]
    resources = ["*"]

    principals {
      type = "AWS"
      # This is a role that your Spacelift worker is able to assume.
      identifiers = [var.spacelift_arn]
    }
  }

  lifecycle {
    enabled = var.spacelift_arn != null
  }
}

resource "aws_iam_role" "spacelift_admin" {
  name               = "spacelift-admin"
  assume_role_policy = data.aws_iam_policy_document.spacelift_assume.json

  lifecycle {
    enabled = var.spacelift_arn != null
  }
}

resource "aws_iam_policy_attachment" "admin" {
  name       = "spacelift-admin-attach"
  roles      = [aws_iam_role.spacelift_admin.name]
  policy_arn = data.aws_iam_policy.admin.arn

  lifecycle {
    enabled = var.spacelift_arn != null
  }
}

# Spacelift This solutions is for if you are storing your state in Spacelift
# instead of AWS. The RBAC changes will allow only certain autheticated
# Spacelift user to access the state without changing the state in the same way
# the S3 solution does above. The administrative stack where this configuration
# will run is defined outside of this repo, and if you need one, you will need
# to provision it first in the UI to avoid the chicken and egg problem.

resource "spacelift_stack" "demo" {
  autodeploy = true
  branch = "main"
  description = "Stack that will hold our Terraform state."
  name = "LocalPlanningDemo"
  repository = "spacelift-local-demo"
  project_root = "demo"



  labels = {
    
  }
}

resource "spacelift_stack_activator" {
  enabled = true
  stack_id = spacelift.demo.id
}

resource "spacelift_role_attachment"

# resource "spacelift_context" ""

# resource "spacelift_context_attachment" ""

