# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/variables.tf
# Author: Kezie Iroha
# Description: variables for vpc module
# ------------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones to use"
  type        = list(string)
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"

  validation {
    condition     = length(var.private_subnets) == length(distinct(var.private_subnets))
    error_message = "Duplicate CIDR blocks detected within private_subnets. Please use unique CIDR ranges."
  }
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDR blocks"

  validation {
    condition     = length(var.public_subnets) == length(distinct(var.public_subnets))
    error_message = "Duplicate CIDR blocks detected within public_subnets. Please use unique CIDR ranges."
  }
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of CIDR blocks allowed to connect to bastion via SSH"
  default     = []
}
