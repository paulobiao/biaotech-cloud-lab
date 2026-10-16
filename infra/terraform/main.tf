locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# One file per concern. NOTHING here has been applied; see docs/aws-zero-spend-guardrails.md.
#   network.tf     - VPC, 2 public subnets, IGW, routes, security groups (no NAT gateway)
#   ecr.tf         - ECR repository + lifecycle policy
#   iam.tf         - ECS task execution role, task role
#   github_oidc.tf - GitHub OIDC provider + repo/branch-scoped deploy role
#   ecs.tf         - ECS cluster, task definition, Fargate service
#   alb.tf         - Application Load Balancer, target group, HTTP listener
#   cloudwatch.tf  - log group (short retention), alarms
