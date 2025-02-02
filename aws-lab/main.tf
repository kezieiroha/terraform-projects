# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  deployment_regions = {
    "us-east-1" = {
      vpc_cidr_block  = "10.0.0.0/16"
      az_count        = 2
      private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
      public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]
    }
  }
}

module "ec2" {
  source      = "./modules/ec2"
  vpc_details = module.vpc.vpc_details
}


