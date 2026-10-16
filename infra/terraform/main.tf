locals {
  name_prefix = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Planned resources, added one concern per file as each roadmap phase lands:
#   network.tf     - VPC, public subnets in 2 AZs, security groups (no NAT gateway)  Phase 2
#   ecr.tf         - ECR repository, scan on push, lifecycle policy                  Phase 3
#   ecs.tf         - ECS cluster, task definition, Fargate service                   Phase 4
#   alb.tf         - Application Load Balancer, target group (/ready), listener      Phase 4
#   iam.tf         - task execution role, task role                                  Phase 4
#   github_oidc.tf - GitHub OIDC provider + repo-scoped deploy role                  Phase 5
#   cloudwatch.tf  - log group with retention, alarms                                Phase 6
