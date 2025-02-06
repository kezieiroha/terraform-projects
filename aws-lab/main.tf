# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = var.vpc_name
  vpc_cidr_block     = var.vpc_cidr_block
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
}

module "ec2" {
  source           = "./modules/ec2"
  vpc_details      = module.vpc.vpc_details
  ec2_az_overrides = var.ec2_az_overrides
}

module "aurora-postgres" {
  source                    = "./modules/aurora-postgres"
  db_subnet_group_name      = module.vpc.vpc_details.db_subnet_group
  db_vpc_security_group_ids = [module.vpc.vpc_details.security_groups.database]
  db_subnet_ids             = module.vpc.vpc_details.subnets.private
  db_availability_zones     = module.vpc.vpc_details.availability_zones
}
