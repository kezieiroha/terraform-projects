# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

module "iam" {
  source                = "./modules/iam"
  aws_region            = var.aws_region
  aws_account_id        = var.aws_account_id
  db_cluster_identifier = module.rds-aurora-cluster.db_cluster_identifier
  db_iam_user           = "iam_db_user"
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

module "rds-aurora-cluster" {
  source                    = "./modules/rds-aurora-cluster"
  vpc_details               = module.vpc.vpc_details
  database_name             = var.database_name
  db_master_password        = var.db_master_password
  db_instance_class         = var.db_instance_class
  db_cluster_instance_count = var.db_cluster_instance_count
  iam_role_arn              = module.iam.aurora_auth_role_arn
  deploy_aurora             = var.deploy_aurora
  db_deletion_protection    = var.db_deletion_protection
  environment               = var.environment
}


