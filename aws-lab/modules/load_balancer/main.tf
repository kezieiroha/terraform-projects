# ------------------------------------------------------------------------------
# Module: load_balancer
# File: modules/load_balancer/main.tf
# Author: Kezie Iroha
# Description: Application Load Balancer for web tier and internal load balancer for app tier
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Web Tier Application Load Balancer (External)
# ------------------------------------------------------------------------------
resource "aws_lb" "web_alb" {
  name               = "${var.environment}-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.vpc_details.subnets.public

  enable_deletion_protection = var.enable_deletion_protection

  # Optional access logs if needed
  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "web-alb-logs"
      enabled = true
    }
  }

  tags = {
    Name        = "${var.environment}-web-alb"
    Environment = var.environment
  }
}

# Target group for web tier instances
resource "aws_lb_target_group" "web_tg" {
  name     = "${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_details.vpc_id

  health_check {
    path                = var.web_health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = {
    Name        = "${var.environment}-web-tg"
    Environment = var.environment
  }
}

# HTTP listener for web ALB
resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  # Redirect to HTTPS if SSL is enabled
  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # Forward to target group if HTTPS is not enabled
  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.web_tg.arn
    }
  }
}

# HTTPS listener for web ALB (if SSL is enabled)
resource "aws_lb_listener" "web_https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ------------------------------------------------------------------------------
# App Tier Internal Load Balancer 
# ------------------------------------------------------------------------------
resource "aws_lb" "app_alb" {
  name               = "${var.environment}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb_sg.id]
  subnets            = var.vpc_details.subnets.private

  enable_deletion_protection = var.enable_deletion_protection

  # Optional access logs if needed
  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = "app-alb-logs"
      enabled = true
    }
  }

  tags = {
    Name        = "${var.environment}-app-alb"
    Environment = var.environment
  }
}

# Target group for app tier instances
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.environment}-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_details.vpc_id

  health_check {
    path                = var.app_health_check_path
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }

  tags = {
    Name        = "${var.environment}-app-tg"
    Environment = var.environment
  }
}

# HTTP listener for app ALB
resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ------------------------------------------------------------------------------
# Security Groups for Load Balancers
# ------------------------------------------------------------------------------
# Security group for external ALB
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for web tier ALB"
  vpc_id      = var.vpc_details.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  # Allow HTTPS from anywhere if SSL is enabled
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow HTTPS from anywhere"
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

# Security group for internal ALB
resource "aws_security_group" "internal_alb_sg" {
  name        = "${var.environment}-internal-alb-sg"
  description = "Security group for app tier internal ALB"
  vpc_id      = var.vpc_details.vpc_id

  # Allow traffic from web tier security group to app port
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.vpc_details.security_groups.web]
    description     = "Allow traffic from web tier to app port"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "${var.environment}-internal-alb-sg"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# Add rule to existing web security group to allow traffic from ALB
# ------------------------------------------------------------------------------
resource "aws_security_group_rule" "web_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = var.vpc_details.security_groups.web
  source_security_group_id = aws_security_group.alb_sg.id
  description              = "Allow HTTP traffic from ALB"
}

# ------------------------------------------------------------------------------
# Add rule to existing app security group to allow traffic from internal ALB
# ------------------------------------------------------------------------------
resource "aws_security_group_rule" "app_from_internal_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = var.vpc_details.security_groups.app
  source_security_group_id = aws_security_group.internal_alb_sg.id
  description              = "Allow HTTP traffic from internal ALB"
}
