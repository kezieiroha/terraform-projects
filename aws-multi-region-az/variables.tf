# ------------------------------------------------------------------------------
# File: variables.tf
# Author: Kezie Iroha
# Description: Parent variables for project
# ------------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "key_name" {
  description = "The name of the SSH key pair to be used for EC2 instances"
  type        = string
  default     = ""
}

variable "deployment_regions" {
  description = "Map of regions with VPC, AZ, and subnet configurations"
  type = map(object({
    vpc_cidr_block     = string
    az_count           = optional(number)
    availability_zones = optional(list(string))
    private_subnets    = list(string)
    public_subnets     = list(string)
  }))
}



