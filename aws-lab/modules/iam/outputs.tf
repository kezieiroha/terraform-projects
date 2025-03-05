# ------------------------------------------------------------------------------
# Module: iam
# File: modules/iam/outputs.tf
# Author: Kezie Iroha
# Description: outputs for iam module
# ------------------------------------------------------------------------------

output "aurora_auth_role_arn" {
  description = "IAM Role ARN for Aurora authentication"
  value       = aws_iam_role.aurora_auth_role.arn
}

output "bastion_instance_profile_name" {
  description = "Instance profile name for bastion host"
  value       = var.enable_bastion_iam ? aws_iam_instance_profile.bastion_profile[0].name : ""
}

output "bastion_role_arn" {
  description = "IAM Role ARN for bastion host"
  value       = var.enable_bastion_iam ? aws_iam_role.bastion_role[0].arn : ""
}
