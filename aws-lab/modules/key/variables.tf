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

/*
variable "private_key_path" {
  description = "Path where the private key will be stored locally"
  type        = string
}

variable "store_private_key_locally" {
  description = "Whether to store the private key locally"
  type        = bool
  default     = true
}
*/
