# ------------------------------------------------------------------------------
# Module: load_balancer
# File: modules/load_balancer/outputs.tf
# Author: Kezie Iroha
# Description: Outputs for load balancer module
# ------------------------------------------------------------------------------

output "web_alb_id" {
  description = "ID of web tier Application Load Balancer"
  value       = aws_lb.web_alb.id
}

output "web_alb_arn" {
  description = "ARN of web tier Application Load Balancer"
  value       = aws_lb.web_alb.arn
}

output "web_alb_dns_name" {
  description = "DNS name of web tier Application Load Balancer"
  value       = aws_lb.web_alb.dns_name
}

output "web_alb_zone_id" {
  description = "Zone ID of web tier Application Load Balancer"
  value       = aws_lb.web_alb.zone_id
}

output "web_target_group_arn" {
  description = "ARN of web tier target group"
  value       = aws_lb_target_group.web_tg.arn
}

output "app_alb_id" {
  description = "ID of app tier Application Load Balancer"
  value       = aws_lb.app_alb.id
}

output "app_alb_arn" {
  description = "ARN of app tier Application Load Balancer"
  value       = aws_lb.app_alb.arn
}

output "app_alb_dns_name" {
  description = "DNS name of app tier Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "app_target_group_arn" {
  description = "ARN of app tier target group"
  value       = aws_lb_target_group.app_tg.arn
}

output "alb_security_group_id" {
  description = "ID of the security group for web ALB"
  value       = aws_security_group.alb_sg.id
}

output "internal_alb_security_group_id" {
  description = "ID of the security group for internal app ALB"
  value       = aws_security_group.internal_alb_sg.id
}
