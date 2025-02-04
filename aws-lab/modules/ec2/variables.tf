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
    vpc_id             = string
    vpc_cidr           = string
    igw_id             = string
    nat_id             = string
    availability_zones = list(string)
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
  })
}

variable "ec2_az_overrides" {
  description = "Availability Zone overrides for EC2 instances"
  type = object({
    web     = optional(string)
    db      = optional(string)
    bastion = optional(string)
  })
  default = {}

  # Validation: Ensure AZ overrides are within allowed AZs
  validation {
    condition = alltrue([
      for az in [var.ec2_az_overrides.web, var.ec2_az_overrides.db, var.ec2_az_overrides.bastion] :
      az == null || contains(var.vpc_details.availability_zones, az)
    ])
    error_message = "Invalid AZ override detected. All AZs in ec2_az_overrides must be within the specified availability_zones."
  }
}

variable "deploy_alternate_az_set" {
  description = "Deploy an identical set of EC2 instances in an alternate AZ"
  type        = bool
  default     = false
}
