# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

module "iam" {
  source = "./modules/iam"
}

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
  source             = "./modules/aurora-postgres"
  vpc_details        = module.vpc.vpc_details
  database_name      = var.database_name
  db_password        = var.db_password
  db_master_password = var.db_master_password
  db_instance_class  = var.db_instance_class
}
