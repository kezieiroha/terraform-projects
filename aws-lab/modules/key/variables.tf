# ------------------------------------------------------------------------------
# Module: key
# File: modules/key/variables.tf
# Author: Kezie Iroha
# Description: variables for key module
# ------------------------------------------------------------------------------

variable "key_name" {
  description = "Name of the key pair to create"
  type        = string
}

variable "store_locally" {
  description = "Whether to store the private key locally"
  type        = bool
  default     = true
}

variable "store_in_secrets_manager" {
  description = "Whether to store the private key in AWS Secrets Manager"
  type        = bool
  default     = false
}
