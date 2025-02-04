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

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = element(var.vpc_details.subnets.public, var.ec2_az_override["web"] != "" ? index(var.vpc_details.availability_zones, var.ec2_az_override["web"]) : 0)
  vpc_security_group_ids = [var.vpc_details.security_groups.web]
  key_name               = var.key_name
  tags = {
    Name = "EC2 Web"
  }
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = element(var.vpc_details.subnets.private, var.ec2_az_override["db"] != "" ? index(var.vpc_details.availability_zones, var.ec2_az_override["db"]) : 0)
  vpc_security_group_ids = [var.vpc_details.security_groups.database]
  key_name               = var.key_name
  tags = {
    Name = "EC2 DB"
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = element(var.vpc_details.subnets.public, var.ec2_az_override["bastion"] != "" ? index(var.vpc_details.availability_zones, var.ec2_az_override["bastion"]) : 0)
  vpc_security_group_ids = [var.vpc_details.security_groups.bastion]
  key_name               = var.key_name
  tags = {
    Name = "EC2 Public Bastion"
  }
}

