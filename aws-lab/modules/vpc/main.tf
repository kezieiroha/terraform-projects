# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/main.tf
# Author: Kezie Iroha
# Description: main for vpc module
# ------------------------------------------------------------------------------

variable "deployment_region" {
  description = "The region for deployment"
  type        = string
}

variable "region_config" {
  description = "Configuration for the region"
  type = object({
    vpc_cidr_block     = string
    az_count           = optional(number)
    availability_zones = optional(list(string))
    private_subnets    = list(string)
    public_subnets     = list(string)
  })
}

# VPC Creation
resource "aws_vpc" "main" {
  cidr_block           = var.region_config.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.deployment_region}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = { for index, subnet in var.region_config.public_subnets : "${var.deployment_region}-public-${index}" => {
    vpc_id     = aws_vpc.main.id
    cidr_block = subnet
    az         = var.region_config.availability_zones != null ? var.region_config.availability_zones[index] : null
  } }
  vpc_id                  = each.value.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name = each.key
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = { for index, subnet in var.region_config.private_subnets : "${var.deployment_region}-private-${index}" => {
    vpc_id     = aws_vpc.main.id
    cidr_block = subnet
    az         = var.region_config.availability_zones != null ? var.region_config.availability_zones[index] : null
  } }
  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = {
    Name = each.key
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.deployment_region}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.deployment_region}-public-route"
  }
}

# NAT Gateway (Optional)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.deployment_region}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["${var.deployment_region}-public-0"].id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.deployment_region}-nat-gw"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "${var.deployment_region}-private-route"
  }
}

# Security Groups (Dynamic Naming)
resource "aws_security_group" "web" {
  name        = "${var.deployment_region}-web-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.deployment_region}-web-sg"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.deployment_region}-app-sg"
  description = "Allow traffic from web servers"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.deployment_region}-app-sg"
  }
}

resource "aws_security_group" "database" {
  name        = "${var.deployment_region}-database-sg"
  description = "Allow MySQL access from app servers"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.deployment_region}-database-sg"
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.deployment_region}-bastion-sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.deployment_region}-bastion-sg"
  }
}
