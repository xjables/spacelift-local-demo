

# Credentials populated from env variables of the API Key we created. In a real setup, these
# crendentials are automatically injected in via the Spacelift runtime. 
provider "spacelift" {}

# The github repository that is referenced should be the one where this code lives. By running the
# stack in Spacelift, this code with import and configure the stack from which it runs. Chicken?
# Meet egg.
resource "spacelift_stack" "admin" {
  name                             = "Spacelift"
  slug                             = "spacelift"
  space_id                         = "root"
  allow_run_promotion              = false
  repository                       = var.github_repository
  project_root                     = "setup/admin"
  branch                           = "main"
  manage_state                     = true
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true
  terraform_workflow_tool          = "OPEN_TOFU"
  enable_local_preview             = true
  terraform_version                = "~>1.12"
}

import {
  to = spacelift_stack.admin
  id = "spacelift"
}

# These further stacks are for the next stages of the demo
resource "spacelift_stack" "s3_state" {
  name                             = "s3-state"
  slug                             = "s3-state"
  space_id                         = "root"
  allow_run_promotion              = false
  repository                       = var.github_repository
  project_root                     = "demo"
  branch                           = "main"
  manage_state                     = false # We'll manage this in S3
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true
  terraform_workflow_tool          = "OPEN_TOFU"
  enable_local_preview             = true
  terraform_version                = "~>1.12"
}

resource "spacelift_stack" "spacelift_state" {
  name                             = "spacelift-state"
  slug                             = "spacelift-state"
  space_id                         = "root"
  allow_run_promotion              = false
  repository                       = var.github_repository
  project_root                     = "demo"
  branch                           = "main"
  manage_state                     = true # We'll manage this in Spacelift
  terraform_smart_sanitization     = true
  enable_well_known_secret_masking = true
  terraform_workflow_tool          = "OPEN_TOFU"
  enable_local_preview             = true
  terraform_version                = "~>1.12"
}
