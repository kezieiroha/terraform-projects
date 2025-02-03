# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

module "vpc" {
  source             = "./modules/vpc"
  deployment_regions = var.deployment_regions
}

module "ec2" {
  for_each    = var.deployment_regions
  source      = "./modules/ec2"
  key_name    = var.key_name
  vpc_details = module.vpc.vpc_details[each.key]
}
