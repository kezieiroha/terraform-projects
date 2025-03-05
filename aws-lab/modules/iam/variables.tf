# ------------------------------------------------------------------------------
# Module: iam
# File: modules/iam/variables.tf
# Author: Kezie Iroha
# Description: variables for iam module
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "iam_role_name" {
  description = "IAM role name for Aurora authentication"
  type        = string
  default     = "AuroraAuthRole"
}

variable "db_cluster_identifier" {
  description = "Aurora Cluster Identifier"
  type        = string
}

variable "db_iam_user" {
  description = "IAM User for Aurora authentication"
  type        = string
  default     = "iam_db_user"
}

variable "enable_bastion_iam" {
  description = "Enable IAM resources for bastion host"
  type        = bool
  default     = true
}
