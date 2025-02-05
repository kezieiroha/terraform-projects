# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/main.tf
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

# Determine the default and alternate AZs
locals {
  az_list      = var.vpc_details.availability_zones
  primary_az   = local.az_list[0]
  alternate_az = local.az_list[1]

  # Apply override if provided, otherwise use defaults
  web_az     = coalesce(var.ec2_az_overrides.web, local.primary_az)
  db_az      = coalesce(var.ec2_az_overrides.db, local.primary_az)
  bastion_az = coalesce(var.ec2_az_overrides.bastion, local.primary_az)

  # For duplicate set
  duplicate_web_az     = local.web_az == local.primary_az ? local.alternate_az : local.primary_az
  duplicate_db_az      = local.db_az == local.primary_az ? local.alternate_az : local.primary_az
  duplicate_bastion_az = local.bastion_az == local.primary_az ? local.alternate_az : local.primary_az
}

locals {
  web_subnet = try(
    element([for i, az in var.vpc_details.availability_zones : var.vpc_details.subnets.public[i] if az == local.web_az], 0),
    null
  )

  db_subnet = try(
    element([for i, az in var.vpc_details.availability_zones : var.vpc_details.subnets.private[i] if az == local.db_az], 0),
    null
  )

  bastion_subnet = try(
    element([for i, az in var.vpc_details.availability_zones : var.vpc_details.subnets.public[i] if az == local.bastion_az], 0),
    null
  )
}

# Primary EC2 Instances
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = local.web_az
  subnet_id              = element(var.vpc_details.subnets.public, 0)
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  tags = {
    Name = "EC2 Web"
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = local.db_az
  subnet_id              = var.vpc_details.subnets.private[index(var.vpc_details.availability_zones, local.db_az)]
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  tags                   = { Name = "EC2 DB" }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = local.bastion_az
  subnet_id              = var.vpc_details.subnets.public[index(var.vpc_details.availability_zones, local.bastion_az)]
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  tags                   = { Name = "EC2 Bastion" }
}

# Duplicate EC2 Instances (Conditional Deployment)
resource "aws_instance" "web_duplicate" {
  count                  = var.deploy_alternate_az_set ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = local.duplicate_web_az
  subnet_id              = element(var.vpc_details.subnets.public, 1)
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  tags = {
    Name = "EC2 Web - Duplicate"
  }
}

resource "aws_instance" "db_duplicate" {
  count                  = var.deploy_alternate_az_set ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = local.duplicate_db_az
  subnet_id              = element(var.vpc_details.subnets.private, 1)
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  tags = {
    Name = "EC2 DB - Duplicate"
  }
}

resource "aws_instance" "bastion_duplicate" {
  count                  = var.deploy_alternate_az_set ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  availability_zone      = local.duplicate_bastion_az
  subnet_id              = element(var.vpc_details.subnets.public, 1)
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  tags = {
    Name = "EC2 Public Bastion - Duplicate"
  }
}
