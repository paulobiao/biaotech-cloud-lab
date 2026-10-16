# Credentials are never configured here. Locally they come from the standard AWS
# credential chain (e.g. SSO profile); in CI from GitHub OIDC (Phase 5).
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}
