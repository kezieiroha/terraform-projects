# ------------------------------------------------------------------------------
# Module: auto_scaling
# File: modules/auto_scaling/outputs.tf
# Author: Kezie Iroha
# Description: Outputs for auto scaling module
# ------------------------------------------------------------------------------

output "web_asg_name" {
  description = "Name of web tier Auto Scaling Group"
  value       = var.deploy_web_tier ? aws_autoscaling_group.web[0].name : null
}

output "web_asg_arn" {
  description = "ARN of web tier Auto Scaling Group"
  value       = var.deploy_web_tier ? aws_autoscaling_group.web[0].arn : null
}

output "web_launch_template_id" {
  description = "ID of web tier Launch Template"
  value       = var.deploy_web_tier ? aws_launch_template.web[0].id : null
}

output "web_launch_template_version" {
  description = "Latest version of web tier Launch Template"
  value       = var.deploy_web_tier ? aws_launch_template.web[0].latest_version : null
}

output "app_asg_name" {
  description = "Name of app tier Auto Scaling Group"
  value       = var.deploy_app_tier ? aws_autoscaling_group.app[0].name : null
}

output "app_asg_arn" {
  description = "ARN of app tier Auto Scaling Group"
  value       = var.deploy_app_tier ? aws_autoscaling_group.app[0].arn : null
}

output "app_launch_template_id" {
  description = "ID of app tier Launch Template"
  value       = var.deploy_app_tier ? aws_launch_template.app[0].id : null
}

output "app_launch_template_version" {
  description = "Latest version of app tier Launch Template"
  value       = var.deploy_app_tier ? aws_launch_template.app[0].latest_version : null
}

output "total_asg_count" {
  description = "Total number of Auto Scaling Groups deployed"
  value       = sum([var.deploy_web_tier ? 1 : 0, var.deploy_app_tier ? 1 : 0])
}
