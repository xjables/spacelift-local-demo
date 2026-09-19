provider "spacelift" {}

data "spacelift_space" "root" {
  space_id = "root"
}

# The github repository that is referenced should be the one where this code lives. By running the
# stack in Spacelift, this code with import and configure the stack from which it runs. Chicken?
# Meet egg.
resource "spacelift_stack" "admin" {
  name                             = "Spacelift"
  slug                             = "spacelift"
  space_id                         = data.spacelift_space.root.id
  allow_run_promotion              = false
  repository                       = "spacelift-local-demo"
  project_root                     = "setup/admin"
  branch                           = "main"
  manage_state                     = true
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true
  terraform_workflow_tool          = "OPEN_TOFU"
  enable_local_preview             = true
  terraform_version                = "~>1.12"

  raw_git {
    url       = "https://github.com"
    namespace = var.git_org
  }
}

import {
  to = spacelift_stack.admin
  id = "spacelift"
}

# These further stacks are for the next stages of the demo
resource "spacelift_stack" "s3_state" {
  name                             = "s3-state"
  slug                             = "s3-state"
  space_id                         = data.spacelift_space.root.id
  allow_run_promotion              = false
  repository                       = "spacelift-local-demo"
  project_root                     = "setup/s3-state"
  branch                           = "main"
  manage_state                     = false # We'll manage this in S3
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true
  terraform_workflow_tool          = "OPEN_TOFU"
  enable_local_preview             = true
  terraform_version                = "~>1.12"

  raw_git {
    url       = "https://github.com"
    namespace = var.git_org
  }
}

# resource "spacelift_stack" "spacelift_state" {
#   name                             = "spacelift-state"
#   slug                             = "spacelift-state"
#   space_id                         = data.spacelift_space.root.id
#   allow_run_promotion              = false
#   repository = "spacelift-local-demo"
#   project_root                     = "setup/spacelift-state"
#   branch                           = "main"
#   manage_state                     = true # We'll manage this in Spacelift
#   terraform_smart_sanitization     = true
#   enable_well_known_secret_masking = true
#   terraform_workflow_tool          = "OPEN_TOFU"
#   enable_local_preview             = true
#   terraform_version                = "~>1.12"

#     raw_git {
#         url       = "https://github.com"
#         namespace = var.git_org
#     }
# }
