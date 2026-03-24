# ------------------------------------------------------------------------------
# File: outputs.tf
# Author: Kezie Iroha
# Description: Parent outputs for project
# ------------------------------------------------------------------------------

# VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_details.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = module.vpc.vpc_details.vpc_cidr
}

output "public_subnets" {
  description = "IDs of the public subnets"
  value       = module.vpc.vpc_details.subnets.public
}

output "private_subnets" {
  description = "IDs of the private subnets"
  value       = module.vpc.vpc_details.subnets.private
}

# Bastion Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.bastion.bastion_public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = module.bastion.bastion_private_ip
}

output "bastion_connection_command" {
  description = "SSH command to connect to the bastion host"
  value       = module.bastion.connection_command
}

# Database Outputs
output "db_endpoint" {
  description = "Endpoint of the database"
  value       = module.rds-aurora-cluster.db_endpoint
}

output "db_cluster_identifier" {
  description = "Identifier of the database cluster"
  value       = module.rds-aurora-cluster.db_cluster_identifier
}

# EC2 Tier Outputs (if deployed)
output "web_instance_public_ips" {
  description = "Public IPs of the web tier instances"
  value       = var.deploy_ec2_tiers && var.deploy_web_tier ? module.ec2[0].public_ips.web : []
}

output "app_instance_private_ips" {
  description = "Private IPs of the app tier instances"
  value       = var.deploy_ec2_tiers && var.deploy_app_tier ? module.ec2[0].private_ips.app : []
}

# Auto Scaling Group Outputs - Version that works with plain module (no count)
output "auto_scaling_web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  value       = var.deploy_auto_scaling && var.deploy_web_tier ? module.auto_scaling[0].web_asg_name : null
}

output "auto_scaling_app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  value       = var.deploy_auto_scaling && var.deploy_app_tier ? module.auto_scaling[0].app_asg_name : null
}

# Key Outputs
output "key_name" {
  description = "Name of the generated key pair"
  value       = module.key.key_name
}

output "key_pair_id" {
  description = "ID of the generated key pair"
  value       = module.key.key_pair_id
}

output "web_alb_dns_name" {
  description = "DNS name of the web tier ALB"
  value       = var.deploy_auto_scaling ? module.load_balancer[0].web_alb_dns_name : null
}

output "app_alb_dns_name" {
  description = "DNS name of the app tier ALB"
  value       = var.deploy_auto_scaling ? module.load_balancer[0].app_alb_dns_name : null
}
