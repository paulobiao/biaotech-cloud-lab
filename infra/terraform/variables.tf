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

variable "container_port" {
  description = "Port the API container listens on (must match the Dockerfile)."
  type        = number
  default     = 3000
}
