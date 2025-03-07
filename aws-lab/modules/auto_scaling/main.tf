# ------------------------------------------------------------------------------
# Module: auto_scaling
# File: modules/auto_scaling/main.tf
# Author: Kezie Iroha
# Description: Auto Scaling Groups for web and app tiers
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Local variables
# ------------------------------------------------------------------------------
locals {
  # Extract names from ARNs for resource labels
  web_alb_name    = element(split("/", var.web_alb_arn), 3)
  web_target_name = element(split("/", var.web_target_group_arn), 3)
  app_alb_name    = element(split("/", var.app_alb_arn), 3)
  app_target_name = element(split("/", var.app_target_group_arn), 3)

  # Template file contents
  web_user_data = templatefile("${path.module}/web_userdata.sh.tpl", {
    environment = var.environment
    aws_region  = var.aws_region
  })

  app_user_data = templatefile("${path.module}/app_userdata.sh.tpl", {
    environment = var.environment
    aws_region  = var.aws_region
  })
}

# ------------------------------------------------------------------------------
# Data sources
# ------------------------------------------------------------------------------
# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

# ------------------------------------------------------------------------------
# Write template files for reference (optional)
# ------------------------------------------------------------------------------
resource "local_file" "web_user_data_script" {
  count    = var.deploy_web_tier ? 1 : 0
  content  = local.web_user_data
  filename = "${path.module}/web_userdata.sh"
}

resource "local_file" "app_user_data_script" {
  count    = var.deploy_app_tier ? 1 : 0
  content  = local.app_user_data
  filename = "${path.module}/app_userdata.sh"
}

# ------------------------------------------------------------------------------
# Web Tier Auto Scaling
# ------------------------------------------------------------------------------
# Launch Template for web tier
resource "aws_launch_template" "web" {
  count         = var.deploy_web_tier ? 1 : 0
  name          = "${var.environment}-web-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.web
  key_name      = var.enable_ssh ? var.key_name : null

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  vpc_security_group_ids = [var.vpc_details.security_groups.web]

  monitoring {
    enabled = true
  }

  # Use template file for user data script
  user_data = base64encode(local.web_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-instance"
      Environment = var.environment
      Tier        = "web"
    }
  }

  tags = {
    Name        = "${var.environment}-web-lt"
    Environment = var.environment
  }
}

# Auto Scaling Group for web tier
resource "aws_autoscaling_group" "web" {
  count            = var.deploy_web_tier ? 1 : 0
  name             = "${var.environment}-web-asg"
  min_size         = var.web_asg_config.min_size
  max_size         = var.web_asg_config.max_size
  desired_capacity = var.web_asg_config.desired_capacity

  # Limit to only the first 2 AZs to better control distribution
  vpc_zone_identifier = slice(var.vpc_details.subnets.public, 0, 2)

  target_group_arns = [var.web_target_group_arn]
  health_check_type = "ELB"

  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web[0].id
    version = "$Latest"
  }

  # Enable instance refresh
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Control instance distribution
  placement_group = var.placement_group_name != "" ? var.placement_group_name : null

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "web"
    propagate_at_launch = true
  }
}

# Scaling policy for web tier - CPU based
resource "aws_autoscaling_policy" "web_cpu" {
  count                  = var.deploy_web_tier ? 1 : 0
  name                   = "${var.environment}-web-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.web[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # Target CPU utilization of 70%
  }
}

# Scaling policy for web tier - Request count based
resource "aws_autoscaling_policy" "web_request" {
  count                  = var.deploy_web_tier ? 1 : 0
  name                   = "${var.environment}-web-request-policy"
  autoscaling_group_name = aws_autoscaling_group.web[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "app/${local.web_alb_name}/targetgroup/${local.web_target_name}"
    }
    target_value = 1000.0 # Target requests per minute per instance
  }
}

# ------------------------------------------------------------------------------
# App Tier Auto Scaling
# ------------------------------------------------------------------------------
# Launch Template for app tier
resource "aws_launch_template" "app" {
  count         = var.deploy_app_tier ? 1 : 0
  name          = "${var.environment}-app-lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.app
  key_name      = var.enable_ssh ? var.key_name : null

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  vpc_security_group_ids = [var.vpc_details.security_groups.app]

  monitoring {
    enabled = true
  }

  # Use template file for user data script
  user_data = base64encode(local.app_user_data)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-app-instance"
      Environment = var.environment
      Tier        = "app"
    }
  }

  tags = {
    Name        = "${var.environment}-app-lt"
    Environment = var.environment
  }
}

# Auto Scaling Group for app tier
resource "aws_autoscaling_group" "app" {
  count            = var.deploy_app_tier ? 1 : 0
  name             = "${var.environment}-app-asg"
  min_size         = var.app_asg_config.min_size
  max_size         = var.app_asg_config.max_size
  desired_capacity = var.app_asg_config.desired_capacity

  # Limit to only the first 2 AZs to better control distribution
  vpc_zone_identifier = slice(var.vpc_details.subnets.private, 0, 2)

  target_group_arns = [var.app_target_group_arn]
  health_check_type = "ELB"

  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app[0].id
    version = "$Latest"
  }

  # Enable instance refresh
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  # Control instance distribution
  placement_group = var.placement_group_name != "" ? var.placement_group_name : null

  # Enable detailed monitoring
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-app-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "app"
    propagate_at_launch = true
  }
}

# Scaling policy for app tier - CPU based
resource "aws_autoscaling_policy" "app_cpu" {
  count                  = var.deploy_app_tier ? 1 : 0
  name                   = "${var.environment}-app-cpu-policy"
  autoscaling_group_name = aws_autoscaling_group.app[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0 # Target CPU utilization of 70%
  }
}

# Scaling policy for app tier - Request count based
resource "aws_autoscaling_policy" "app_request" {
  count                  = var.deploy_app_tier ? 1 : 0
  name                   = "${var.environment}-app-request-policy"
  autoscaling_group_name = aws_autoscaling_group.app[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "app/${local.app_alb_name}/targetgroup/${local.app_target_name}"
    }
    target_value = 800.0 # Target requests per minute per instance
  }
}
