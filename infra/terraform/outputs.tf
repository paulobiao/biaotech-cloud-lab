output "aws_region" {
  description = "Region the configuration targets."
  value       = var.aws_region
}

output "name_prefix" {
  description = "Prefix applied to resource names."
  value       = local.name_prefix
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB (the API endpoint once deployed)."
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository to push the API image to."
  value       = aws_ecr_repository.api.repository_url
}

output "github_deploy_role_arn" {
  description = "Role ARN for aws-actions/configure-aws-credentials (role-to-assume)."
  value       = aws_iam_role.github_deploy.arn
}
