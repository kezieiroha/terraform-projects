# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/main.tf
# Author: Kezie Iroha
# Description: main for vpc module
# ------------------------------------------------------------------------------

# VPC Creation
resource "aws_vpc" "main" {
  for_each             = var.deployment_regions
  cidr_block           = each.value.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${each.key}-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = merge([
    for region, config in var.deployment_regions : {
      for index, subnet in config.public_subnets :
      "${region}-public-${index}" => {
        vpc_id     = aws_vpc.main[region].id
        cidr_block = subnet
        az         = config.availability_zones != null ? config.availability_zones[index] : null
      }
    }
  ]...)
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
  for_each = merge([
    for region, config in var.deployment_regions : {
      for index, subnet in config.private_subnets :
      "${region}-private-${index}" => {
        vpc_id     = aws_vpc.main[region].id
        cidr_block = subnet
        az         = config.availability_zones != null ? config.availability_zones[index] : null
      }
    }
  ]...)
  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.az
  tags = {
    Name = each.key
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  for_each = var.deployment_regions
  vpc_id   = aws_vpc.main[each.key].id
  tags = {
    Name = "${each.key}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  for_each = var.deployment_regions
  vpc_id   = aws_vpc.main[each.key].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[each.key].id
  }
  tags = {
    Name = "${each.key}-public-route"
  }
}

# NAT Gateway (Optional)
resource "aws_eip" "nat" {
  for_each = var.deployment_regions
  domain   = "vpc"
  tags = {
    Name = "${each.key}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each      = var.deployment_regions
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public["${each.key}-public-0"].id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${each.key}-nat-gw"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  for_each = var.deployment_regions
  vpc_id   = aws_vpc.main[each.key].id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = {
    Name = "${each.key}-private-route"
  }
}

# Security Groups (Dynamic Naming)
resource "aws_security_group" "web" {
  for_each    = var.deployment_regions
  name        = "${each.key}-web-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main[each.key].id
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
    Name = "${each.key}-web-sg"
  }
}

resource "aws_security_group" "app" {
  for_each    = var.deployment_regions
  name        = "${each.key}-app-sg"
  description = "Allow traffic from web servers"
  vpc_id      = aws_vpc.main[each.key].id
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web[each.key].id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${each.key}-app-sg"
  }
}

resource "aws_security_group" "database" {
  for_each    = var.deployment_regions
  name        = "${each.key}-database-sg"
  description = "Allow MySQL access from app servers"
  vpc_id      = aws_vpc.main[each.key].id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app[each.key].id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${each.key}-database-sg"
  }
}

resource "aws_security_group" "bastion" {
  for_each    = var.deployment_regions
  name        = "${each.key}-bastion-sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main[each.key].id
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
    Name = "${each.key}-bastion-sg"
  }
}
