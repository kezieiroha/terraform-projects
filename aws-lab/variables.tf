# ------------------------------------------------------------------------------
# File: variables.tf
# Author: Kezie Iroha
# Description: Parent variables for project
# ------------------------------------------------------------------------------

variable "aws_region" {
  description = "The default AWS region for deployment"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "deployment_regions" {
  description = "Map of regions with VPC, AZ, and subnet configurations"
  type = map(object({
    vpc_cidr_block  = string
    az_count        = number
    private_subnets = list(string)
    public_subnets  = list(string)
  }))
}
