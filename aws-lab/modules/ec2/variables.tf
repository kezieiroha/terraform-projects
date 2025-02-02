# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/variables.tf
# Author: Kezie Iroha
# Description: variables for ec2 module
# ------------------------------------------------------------------------------

variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = ""
}

/* 
variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = ""
  validation {
    condition     = var.key_name != ""
    error_message = "The key_name variable must be provided."
  }
}
*/

variable "vpc_details" {
  description = "Details of the VPC"
  type = object({
    vpc_id   = string
    vpc_cidr = string
    vpc_igw  = string
    subnets = object({
      public_bastion = object({
        id         = string
        cidr_block = string
      })
      public_web = object({
        id         = string
        cidr_block = string
      })
      private_app = object({
        id         = string
        cidr_block = string
      })
      private_db = object({
        id         = string
        cidr_block = string
      })
    })
    security_groups = object({
      web      = string
      app      = string
      database = string
      bastion  = string
    })
  })
}
