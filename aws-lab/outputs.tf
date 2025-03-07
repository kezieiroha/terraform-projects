# ------------------------------------------ 
# File: outputs.tf
# Author: Kezie Iroha
# Description: Parent outputs for project 
# ----------------------------------------- 

# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_details.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = module.vpc.vpc_details.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.vpc_details.subnets.public
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.vpc_details.subnets.private
}

# Bastion Outputs
output "bastion_instance_id" {
  description = "ID of the bastion host"
  value       = module.bastion.bastion_instance_id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to the bastion host"
  value       = module.bastion.connection_command
}

# Database Outputs
output "db_endpoint" {
  description = "Endpoint of the database"
  value       = module.rds-aurora-cluster.db_endpoint
}

output "db_identifier" {
  description = "Identifier of the database"
  value       = module.rds-aurora-cluster.db_cluster_identifier
}

# EC2 Outputs (if deployed without auto scaling)
output "ec2_instance_ids" {
  description = "IDs of the EC2 instances (if deployed without auto scaling)"
  value       = var.deploy_ec2_tiers && !var.deploy_auto_scaling ? module.ec2[0].instance_ids : null
}

output "ec2_public_ips" {
  description = "Public IPs of the web tier EC2 instances (if deployed without auto scaling)"
  value       = var.deploy_ec2_tiers && !var.deploy_auto_scaling ? module.ec2[0].public_ips : null
}

# Load Balancer Outputs (if auto scaling is enabled)
output "web_alb_dns_name" {
  description = "DNS name of web tier Application Load Balancer"
  value       = var.deploy_auto_scaling ? module.load_balancer[0].web_alb_dns_name : null
}

output "app_alb_dns_name" {
  description = "DNS name of app tier Application Load Balancer"
  value       = var.deploy_auto_scaling ? module.load_balancer[0].app_alb_dns_name : null
}

# Auto Scaling Outputs (if auto scaling is enabled)
output "web_asg_name" {
  description = "Name of web tier Auto Scaling Group"
  value       = var.deploy_auto_scaling && var.deploy_web_tier ? module.auto_scaling[0].web_asg_name : null
}

output "app_asg_name" {
  description = "Name of app tier Auto Scaling Group"
  value       = var.deploy_auto_scaling && var.deploy_app_tier ? module.auto_scaling[0].app_asg_name : null
}

# Deployment Summary
output "deployment_type" {
  description = "Summary of deployment type"
  value = {
    using_auto_scaling = var.deploy_auto_scaling
    web_tier_deployed  = var.deploy_auto_scaling ? var.deploy_web_tier : (var.deploy_ec2_tiers ? var.deploy_web_tier : false)
    app_tier_deployed  = var.deploy_auto_scaling ? var.deploy_app_tier : (var.deploy_ec2_tiers ? var.deploy_app_tier : false)
    database_type      = var.db_engine == "aurora-postgresql" ? "Aurora PostgreSQL" : "RDS PostgreSQL (${var.rds_deployment_type})"
  }
}

# Access Information
output "application_url" {
  description = "URL to access the web application"
  value       = var.deploy_auto_scaling && var.deploy_web_tier ? "http://${module.load_balancer[0].web_alb_dns_name}" : (var.deploy_ec2_tiers && var.deploy_web_tier && !var.deploy_auto_scaling ? "http://${module.ec2[0].public_ips.web[0]}" : null)
}
