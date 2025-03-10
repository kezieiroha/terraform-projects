# ------------------------------------------------------------------------------
# Module: auto_scaling
# File: modules/auto_scaling/main.tf
# Author: Kezie Iroha  
# Description: Auto Scaling module for web and app tiers
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

# -----------------------------------------------------------------------------
# Web Tier Auto Scaling Group
# -----------------------------------------------------------------------------
resource "aws_launch_template" "web_template" {
  count         = var.deploy_web_tier ? 1 : 0
  name_prefix   = "web-template-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.web

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.vpc_details.security_groups.web]
  }

  key_name = var.enable_ssh ? var.key_name : null

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Tier - Auto Scaling Group</h1>" > /var/www/html/index.html
    echo "<p>Region: ${var.aws_region}</p>" >> /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "Web-ASG-Instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_asg" {
  count               = var.deploy_web_tier ? 1 : 0
  name                = "web-asg-${var.environment}"
  vpc_zone_identifier = var.vpc_details.subnets.public

  # Set explicit capacity limits
  min_size         = var.web_asg_config.min_size
  max_size         = var.web_asg_config.max_size
  desired_capacity = var.web_asg_config.desired_capacity

  # Increase cooldown to prevent rapid scaling events
  default_cooldown = 300

  launch_template {
    id      = aws_launch_template.web_template[0].id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  target_group_arns = var.web_target_group_arn != "" ? [var.web_target_group_arn] : []

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

  # Instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity] # Let ASG policies handle desired capacity changes
  }

  tag {
    key                 = "Name"
    value               = "Web-ASG-Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# Web tier CPU-based scaling policy (Target Tracking)
resource "aws_autoscaling_policy" "web_cpu_policy" {
  count                  = var.deploy_web_tier ? 1 : 0
  name                   = "web-cpu-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.web_asg[0].name
  policy_type            = "TargetTrackingScaling"

  # Increased cooldown
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    # More conservative target - scale out at 70% CPU
    target_value = 70.0
  }
}

# -----------------------------------------------------------------------------
# App Tier Auto Scaling Group
# -----------------------------------------------------------------------------
resource "aws_launch_template" "app_template" {
  count         = var.deploy_app_tier ? 1 : 0
  name_prefix   = "app-template-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_types.app

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.vpc_details.security_groups.app]
  }

  key_name = var.enable_ssh ? var.key_name : null

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>App Tier - Auto Scaling Group</h1>" > /var/www/html/index.html
    echo "<p>Region: ${var.aws_region}</p>" >> /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "App-ASG-Instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app_asg" {
  count               = var.deploy_app_tier ? 1 : 0
  name                = "app-asg-${var.environment}"
  vpc_zone_identifier = var.vpc_details.subnets.private

  # Set explicit capacity limits  
  min_size         = var.app_asg_config.min_size
  max_size         = var.app_asg_config.max_size
  desired_capacity = var.app_asg_config.desired_capacity

  # Increase cooldown to prevent rapid scaling events
  default_cooldown = 300

  launch_template {
    id      = aws_launch_template.app_template[0].id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  target_group_arns = var.app_target_group_arn != "" ? [var.app_target_group_arn] : []

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

  # Instance refresh for rolling updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity] # Let ASG policies handle desired capacity changes
  }

  tag {
    key                 = "Name"
    value               = "App-ASG-Instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# App tier CPU-based scaling policy (Target Tracking)
resource "aws_autoscaling_policy" "app_cpu_policy" {
  count                  = var.deploy_app_tier ? 1 : 0
  name                   = "app-cpu-tracking-policy"
  autoscaling_group_name = aws_autoscaling_group.app_asg[0].name
  policy_type            = "TargetTrackingScaling"

  # Increased cooldown
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    # More conservative target - scale out at 70% CPU
    target_value = 70.0
  }
}
