terraform {
  backend "s3" {
    bucket = "spacelift-local-demo-444839312137-us-west-2-an"
    key    = "demo.tfstate"
    region = "us-west-2"

    assume_role = {
      role_arn     = var.role
      session_name = "backend-access"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "role" {
  type = string
}

provider "aws" {
  region = "us-west-2"

  assume_role {
    # By setting this variable, we can selectively chose the role we want to use, either Spacelift or the planner role.
    role_arn     = var.role
    session_name = "spacelift-demo-stack"
  }
}

# resource "aws_ssm_parameter" "demo" {
#   name = "/opentofu/demo"
#   type = "String"
#   value = "I'll take a crab juice."
# }
