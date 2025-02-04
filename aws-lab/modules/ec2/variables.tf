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
}

variable "deploy_alternate_az_set" {
  description = "Deploy an identical set of EC2 instances in an alternate AZ"
  type        = bool
  default     = false
}
