# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

module "vpc" {
  source   = "./modules/vpc"
  for_each = var.deployment_regions

  region          = each.key
  vpc_cidr_block  = each.value.vpc_cidr_block
  az_count        = each.value.az_count
  private_subnets = each.value.private_subnets
  public_subnets  = each.value.public_subnets

  providers = {
    aws = aws[replace(each.key, "-", "_")] # Referencing provider aliases
  }
}

module "ec2" {
  source   = "./modules/ec2"
  for_each = var.deployment_regions

  key_name    = var.key_name
  vpc_details = module.vpc[each.key].vpc_details

  providers = {
    aws = aws[replace(each.key, "-", "_")] # Referencing provider aliases
  }
}
