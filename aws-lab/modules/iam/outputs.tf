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
