# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/variables.tf
# Author: Kezie Iroha
# Description: variables for vpc module
# ------------------------------------------------------------------------------

variable "deployment_regions" {
  description = "Map of regions with VPC, AZ, and subnet configurations"
  type = map(object({
    vpc_cidr_block     = string
    availability_zones = optional(list(string))
    az_count           = optional(number)
    private_subnets    = list(string)
    public_subnets     = list(string)
  }))

  validation {
    condition     = length(var.deployment_regions) > 0
    error_message = <<EOT
You must specify at least one region in 'deployment_regions'.
Specify one or more regions like this:
deployment_regions = {
  "us-east-1" = {
    vpc_cidr_block     = "10.0.0.0/16"
    az_count           = 2
    private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
    public_subnets     = ["10.0.3.0/24", "10.0.4.0/24"]
  },
  "eu-west-1" = {
    vpc_cidr_block     = "10.1.0.0/16"
    availability_zones = ["eu-west-1a", "eu-west-1b"]
    private_subnets    = ["10.1.1.0/24", "10.1.2.0/24"]
    public_subnets     = ["10.1.3.0/24", "10.1.4.0/24"]
  }
}
EOT
  }
}

