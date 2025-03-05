# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/main.tf
# Author: Kezie Iroha
# Description: main for ec2 module - web and app tiers only
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

# Determine the default and alternate AZs
locals {
  az_list      = var.vpc_details.availability_zones
  primary_az   = local.az_list[0]
  alternate_az = length(local.az_list) > 1 ? local.az_list[1] : local.primary_az

  # Apply override if provided, otherwise use defaults
  web_az = try(var.ec2_az_overrides.web, local.primary_az)
  app_az = try(var.ec2_az_overrides.app, local.primary_az)

  # For duplicate set
  duplicate_web_az = local.web_az == local.primary_az ? local.alternate_az : local.primary_az
  duplicate_app_az = local.app_az == local.primary_az ? local.alternate_az : local.primary_az

  # Get the subnet indices
  web_subnet_index = index(var.vpc_details.availability_zones, local.web_az)
  app_subnet_index = index(var.vpc_details.availability_zones, local.app_az)

  duplicate_web_subnet_index = index(var.vpc_details.availability_zones, local.duplicate_web_az)
  duplicate_app_subnet_index = index(var.vpc_details.availability_zones, local.duplicate_app_az)
}

# Web Tier EC2 Instances - Optional
resource "aws_instance" "web" {
  count                  = var.deploy_web_tier ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_types.web
  availability_zone      = local.web_az
  subnet_id              = var.vpc_details.subnets.public[local.web_subnet_index]
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 Web Tier"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Install Apache for a basic web server
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Tier - $(hostname -f)</h1>" > /var/www/html/index.html
    echo "<p>Availability Zone: ${local.web_az}</p>" >> /var/www/html/index.html
  EOF
}

# App Tier EC2 Instances - Optional
resource "aws_instance" "app" {
  count                  = var.deploy_app_tier ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_types.app
  availability_zone      = local.app_az
  subnet_id              = var.vpc_details.subnets.private[local.app_subnet_index]
  vpc_security_group_ids = [var.vpc_details.security_groups.app]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 App Tier"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Install a basic app server
    yum update -y
    # Additional app tier setup could go here
    echo "App Tier Deployed - $(hostname -f)" > /tmp/app-deployed.txt
  EOF
}

# Duplicate Web Instance for high availability (optional)
resource "aws_instance" "web_duplicate" {
  count                  = var.deploy_web_tier && var.deploy_alternate_az_set ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_types.web
  availability_zone      = local.duplicate_web_az
  subnet_id              = var.vpc_details.subnets.public[local.duplicate_web_subnet_index]
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 Web Tier - Duplicate"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Install Apache for a basic web server
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Web Tier Duplicate - $(hostname -f)</h1>" > /var/www/html/index.html
    echo "<p>Availability Zone: ${local.duplicate_web_az}</p>" >> /var/www/html/index.html
  EOF
}

# Duplicate App Instance for high availability (optional)
resource "aws_instance" "app_duplicate" {
  count                  = var.deploy_app_tier && var.deploy_alternate_az_set ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_types.app
  availability_zone      = local.duplicate_app_az
  subnet_id              = var.vpc_details.subnets.private[local.duplicate_app_subnet_index]
  vpc_security_group_ids = [var.vpc_details.security_groups.app]
  key_name               = var.enable_ssh ? var.key_name : null

  tags = {
    Name = "EC2 App Tier - Duplicate"
  }

  user_data = <<-EOF
    #!/bin/bash
    # Install a basic app server
    yum update -y
    # Additional app tier setup could go here
    echo "App Tier Duplicate Deployed - $(hostname -f)" > /tmp/app-deployed.txt
  EOF
}
