# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/variables.tf
# Author: Kezie Iroha
# Description: variables for ec2 module
# ------------------------------------------------------------------------------

# SSH Key Pair
variable "key_name" {
  description = "The name of the SSH key pair"
  type        = string
  default     = ""
}

variable "vpc_details" {
  description = "Details of the VPC"
  type = object({
    vpc_id   = string
    vpc_cidr = string
    igw_id   = string
    nat_id   = string
    subnets = object({
      public  = list(string)
      private = list(string)
    })
    security_groups = object({
      web      = string
      app      = string
      database = string
      bastion  = string
    })
    availability_zones = list(string)
  })

  validation {
    condition = length([
      for cidr in var.vpc_details.subnets.private : cidr
      if contains(var.vpc_details.subnets.public, cidr)
    ]) == 0

    error_message = join("", [
      "Duplicate CIDR blocks detected between public and private subnets. ",
      "Duplicated CIDRs: ",
      join(", ", [
        for cidr in var.vpc_details.subnets.private : cidr
        if contains(var.vpc_details.subnets.public, cidr)
      ])
    ])
  }
}

variable "deploy_alternate_az_set" {
  description = "Flag to deploy identical EC2 set in an alternate AZ"
  type        = bool
  default     = false
}

variable "ec2_az_overrides" {
  description = "Availability Zone overrides for EC2 instances"
  type = object({
    web     = optional(string)
    db      = optional(string)
    bastion = optional(string)
  })
  default = {}

  validation {
    condition = alltrue([
      !contains(keys(var.ec2_az_overrides), "web") || contains(var.vpc_details.availability_zones, var.ec2_az_overrides.web),
      !contains(keys(var.ec2_az_overrides), "db") || contains(var.vpc_details.availability_zones, var.ec2_az_overrides.db),
      !contains(keys(var.ec2_az_overrides), "bastion") || contains(var.vpc_details.availability_zones, var.ec2_az_overrides.bastion)
    ])
    error_message = "Invalid AZ override detected. All AZs in ec2_az_overrides must be within the specified availability_zones."
  }
}
