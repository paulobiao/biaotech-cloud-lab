terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Phase 1 uses no backend (validated with `terraform init -backend=false`).
  # Phase 2 decides on remote state (S3 with native locking) before any apply.
}
