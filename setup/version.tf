terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.0"
    }
    spacelift = {
        source = "spacelift-io/spacelift"
        version = "~> 1.0"
    }
  }
}