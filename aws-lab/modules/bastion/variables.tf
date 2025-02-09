# ------------------------------------------------------------------------------
# Module: bastion
# File: modules/bastion/variables.tf
# Author: Kezie Iroha
# Description: variables for bastion module
# ------------------------------------------------------------------------------

variable "vpc_details" {
  description = "VPC details including subnets and security groups"
  type = object({
    subnets = object({
      public  = list(string)
      private = list(string)
    })
    security_groups = object({
      bastion = string
    })
  })
}

variable "instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH Key Name"
  type        = string
  default     = ""
}

variable "enable_ssh" {
  description = "Enable SSH access to Bastion"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Enable AWS SSM Session Manager"
  type        = bool
  default     = true
}
