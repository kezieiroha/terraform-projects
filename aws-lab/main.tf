# ------------------------------------------------------------------------------
# File: main.tf
# Author: Kezie Iroha
# Description: Parent main for project
# ------------------------------------------------------------------------------

# Generate SSH key if needed
module "key" {
  source   = "./modules/key"
  key_name = var.key_name
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = var.vpc_name
  vpc_cidr_block     = var.vpc_cidr_block
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
}

module "iam" {
  source                = "./modules/iam"
  aws_region            = var.aws_region
  aws_account_id        = var.aws_account_id
  db_cluster_identifier = module.rds-aurora-cluster.db_cluster_identifier
  db_iam_user           = var.db_iam_user
  enable_bastion_iam    = true
}

# Bastion is always deployed
module "bastion" {
  source      = "./modules/bastion"
  vpc_details = module.vpc.vpc_details
  key_name    = module.key.key_name
  enable_ssh  = var.enable_ssh
  enable_ssm  = var.enable_ssm
  # We still pass this for backward compatibility, but it's not used in the new approach
  private_key_path     = ""
  instance_type        = var.instance_types.bastion
  iam_instance_profile = module.iam.bastion_instance_profile_name
  aws_region           = var.aws_region
  db_endpoint          = module.rds-aurora-cluster.db_endpoint
}

# EC2 tiers are optional based on flags
module "ec2" {
  count                   = var.deploy_ec2_tiers ? 1 : 0
  source                  = "./modules/ec2"
  vpc_details             = module.vpc.vpc_details
  key_name                = module.key.key_name
  ec2_az_overrides        = var.ec2_az_overrides
  deploy_web_tier         = var.deploy_web_tier
  deploy_app_tier         = var.deploy_app_tier
  deploy_alternate_az_set = var.deploy_alternate_az_set
  instance_types = {
    web = var.instance_types.web
    app = var.instance_types.app
  }
  enable_ssh = var.enable_ssh
}

module "rds-aurora-cluster" {
  source                        = "./modules/rds-aurora-cluster"
  vpc_details                   = module.vpc.vpc_details
  database_name                 = var.database_name
  db_master_password            = var.db_master_password
  db_instance_class             = var.db_instance_class
  db_cluster_instance_class     = var.db_cluster_instance_class
  db_cluster_instance_count     = var.db_cluster_instance_count
  iam_role_arn                  = module.iam.aurora_auth_role_arn
  db_engine                     = var.db_engine
  db_engine_version             = var.db_engine_version
  rds_deployment_type           = var.rds_deployment_type
  db_deletion_protection        = var.db_deletion_protection
  skip_final_snapshot           = var.skip_final_snapshot
  environment                   = var.environment
  db_allocated_storage          = var.db_allocated_storage
  db_max_allocated_storage      = var.db_max_allocated_storage
  db_parameter_group_family_rds = var.db_parameter_group_family_rds
}
