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
  allowed_ssh_cidrs  = var.allowed_ssh_cidrs
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
  source               = "./modules/bastion"
  vpc_details          = module.vpc.vpc_details
  key_name             = module.key.key_name
  enable_ssh           = var.enable_ssh
  enable_ssm           = var.enable_ssm
  private_key_path     = ""
  instance_type        = var.instance_types.bastion
  iam_instance_profile = module.iam.bastion_instance_profile_name
  aws_region           = var.aws_region
  db_endpoint          = module.rds-aurora-cluster.db_endpoint
  db_engine            = var.db_engine
  environment          = var.environment
}

# EC2 tiers are optional based on flags (only used if not using auto scaling)
module "ec2" {
  count                   = var.deploy_ec2_tiers && !var.deploy_auto_scaling ? 1 : 0
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
  db_cluster_identifier         = var.db_cluster_identifier
  db_storage_type               = var.db_storage_type
  db_iops                       = var.db_iops
}

# New Load Balancer Module (only if auto scaling is enabled)
module "load_balancer" {
  count                      = var.deploy_auto_scaling ? 1 : 0
  source                     = "./modules/load_balancer"
  environment                = var.environment
  vpc_details                = module.vpc.vpc_details
  enable_deletion_protection = false
  enable_access_logs         = var.enable_alb_access_logs
  access_logs_bucket         = var.alb_access_logs_bucket
  web_health_check_path      = var.web_health_check_path
  app_health_check_path      = var.app_health_check_path
  enable_https               = var.enable_https
  certificate_arn            = var.certificate_arn
}

# New Auto Scaling Module (only if auto scaling is enabled)
module "auto_scaling" {
  count           = var.deploy_auto_scaling ? 1 : 0
  source          = "./modules/auto_scaling"
  environment     = var.environment
  vpc_details     = module.vpc.vpc_details
  deploy_web_tier = var.deploy_web_tier
  deploy_app_tier = var.deploy_app_tier
  aws_region      = var.aws_region
  instance_types = {
    web = var.instance_types.web
    app = var.instance_types.app
  }
  key_name             = module.key.key_name
  enable_ssh           = var.enable_ssh
  iam_instance_profile = module.iam.bastion_instance_profile_name
  web_asg_config       = var.web_asg_config
  app_asg_config       = var.app_asg_config
  # Pass ALB and target group ARNs for scaling policies
  web_alb_arn          = module.load_balancer[0].web_alb_arn
  web_target_group_arn = module.load_balancer[0].web_target_group_arn
  app_alb_arn          = module.load_balancer[0].app_alb_arn
  app_target_group_arn = module.load_balancer[0].app_target_group_arn
}
