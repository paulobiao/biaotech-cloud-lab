# Zero-spend gate: with the default (false) every `terraform plan` / `apply` fails
# before anything is created. `terraform validate` is unaffected.
# See docs/aws-zero-spend-guardrails.md before ever setting this to true.
variable "acknowledge_aws_charges" {
  description = "Must be explicitly set to true to plan/apply. Several resources here bill per hour."
  type        = bool
  default     = false

  validation {
    condition     = var.acknowledge_aws_charges
    error_message = "Blocked by zero-spend policy: this configuration creates billable AWS resources (ALB, Fargate, public IPv4, CloudWatch alarms). Read docs/aws-zero-spend-guardrails.md, then pass -var acknowledge_aws_charges=true deliberately."
  }
}

variable "aws_region" {
  description = "AWS region where the lab is deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for all resources."
  type        = string
  default     = "biaotech-cloud-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project_name))
    error_message = "project_name must be 3-24 chars of lowercase letters, digits or hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g. lab, dev)."
  type        = string
  default     = "lab"

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.environment))
    error_message = "environment must be 2-10 chars of lowercase letters or digits."
  }
}

# ---------- Network ----------

variable "vpc_cidr" {
  description = "CIDR block for the lab VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "alb_ingress_cidrs" {
  description = "CIDRs allowed to reach the ALB on HTTP. Narrow to your own IP for private testing."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------- Workload ----------

variable "container_port" {
  description = "Port the API container listens on (must match the Dockerfile)."
  type        = number
  default     = 3000
}

variable "image_tag" {
  description = "Image tag deployed by Terraform on first apply. CI/CD (Phase 5) deploys later tags."
  type        = string
  default     = "bootstrap"
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU, the smallest size)."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MiB (512 is the smallest valid with 256 CPU)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of running tasks. 0 keeps the service defined but stops Fargate compute charges."
  type        = number
  default     = 1
}

# ---------- Observability ----------

variable "log_retention_days" {
  description = "CloudWatch Logs retention. Intentionally short for a lab."
  type        = number
  default     = 7
}

variable "alarm_actions" {
  description = "ARNs (e.g. an SNS topic) notified on alarm. Empty = alarms only change state."
  type        = list(string)
  default     = []
}

# ---------- GitHub OIDC ----------

variable "github_repository" {
  description = "GitHub repository (owner/name) allowed to assume the deploy role."
  type        = string
  default     = "paulobiao/biaotech-cloud-lab"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in owner/name form, without wildcards."
  }
}

variable "github_branch" {
  description = "Only workflows running on this branch can assume the deploy role."
  type        = string
  default     = "main"
}
