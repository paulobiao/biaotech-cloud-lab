output "aws_region" {
  description = "Region the configuration targets."
  value       = var.aws_region
}

output "name_prefix" {
  description = "Prefix applied to resource names."
  value       = local.name_prefix
}
