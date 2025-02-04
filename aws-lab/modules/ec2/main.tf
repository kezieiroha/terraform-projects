# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/variables.tf
# Author: Kezie Iroha
# Description: main for ec2 module
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

# Helper to determine AZ
locals {
  web_az     = coalesce(var.ec2_az_overrides.web, var.vpc_details.availability_zones[0])
  db_az      = coalesce(var.ec2_az_overrides.db, var.vpc_details.availability_zones[0])
  bastion_az = coalesce(var.ec2_az_overrides.bastion, var.vpc_details.availability_zones[0])
}

# Web EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.vpc_details.subnets.public[0]
  availability_zone      = local.web_az
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  key_name               = var.key_name
  tags = {
    Name = "EC2 Web"
  }
}

# Database EC2 Instance
resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.vpc_details.subnets.private[0]
  availability_zone      = local.db_az
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  key_name               = var.key_name
  tags = {
    Name = "EC2 DB"
  }
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = var.vpc_details.subnets.public[0]
  availability_zone      = local.bastion_az
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.key_name
  tags = {
    Name = "EC2 Public Bastion"
  }
}

