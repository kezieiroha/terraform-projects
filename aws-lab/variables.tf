# ------------------------------------------------------------------------------
# File: variables.tf
# Author: Kezie Iroha
# Description: Parent variables for project
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to be used for EC2 instances"
  type        = string
  default     = ""
}


variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
}

variable "availability_zones" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) == length(distinct(var.private_subnets))
    error_message = "Duplicate CIDR blocks detected in private_subnets. Please use unique CIDR ranges."
  }
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)

  validation {
    condition     = length(var.public_subnets) == length(distinct(var.public_subnets))
    error_message = "Duplicate CIDR blocks detected in public_subnets. Please use unique CIDR ranges."
  }
}

variable "ec2_az_overrides" {
  description = "Optional AZ override for each EC2 instance (web, db, bastion)"
  type = object({
    web     = optional(string)
    db      = optional(string)
    bastion = optional(string)
  })
  default = {}
}

variable "deploy_alternate_az_set" {
  description = "Flag to deploy an identical EC2 set in the alternate AZ"
  type        = bool
  default     = false
}
