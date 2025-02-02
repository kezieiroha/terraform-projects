# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/main.tf
# Author: Kezie Iroha
# Description: main for vpc module
# ------------------------------------------------------------------------------

/* 
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public_bastion" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_bastion_subnet_cidr
  availability_zone       = var.public_bastion_az
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Bastion Subnet"
  }
}

resource "aws_subnet" "public_web" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_web_subnet_cidr
  availability_zone       = var.public_web_az
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Web Subnet"
  }
}

resource "aws_subnet" "private_app" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_app_subnet_cidr
  availability_zone = var.private_app_az
  tags = {
    Name = "Private App Subnet"
  }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_db_subnet_cidr
  availability_zone = var.private_db_az
  tags = {
    Name = "Private DB Subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.internet_gateway
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Default route for internet access
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route"
  }
}

resource "aws_route_table_association" "public_bastion" {
  subnet_id      = aws_subnet.public_bastion.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public_web" {
  subnet_id      = aws_subnet.public_web.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "NAT Gateway Elastic IP"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_bastion.id

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "NAT Gateway"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0" # Default route for internet access
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route"
  }
}

resource "aws_route_table_association" "private_app" {
  subnet_id      = aws_subnet.private_app.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "private_db" {
  subnet_id      = aws_subnet.private_db.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to the internet for Lab env
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion Security Group"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "Allow HTTP & HTTPS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
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
    Name = "Web Security Group"
  }
}

resource "aws_security_group" "app" {
  name        = "app"
  description = "Allow HTTP inbound traffic from Web Tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow HTTP traffic from Web Tier"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id] # Allow only from Web Security Group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App Security Group"
  }
}

resource "aws_security_group" "database" {
  name        = "database"
  description = "Allow PostgreSQL inbound traffic from App Tier"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL traffic from App Tier"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id] # Allow only from App Security Group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database Security Group"
  }
}
*/

resource "aws_vpc" "main" {
  for_each = var.deployment_regions

  cidr_block           = each.value.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${each.key}-vpc"
  }
}

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

  vpc_id = aws_vpc.main[each.key].id

  tags = {
    Name = "${each.key}-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  for_each = var.deployment_regions

  vpc_id = aws_vpc.main[each.key].id

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

  domain = "vpc"

  tags = {
    Name = "${each.key}-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  for_each = var.deployment_regions

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public["${each.key}-public-0"].id

  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${each.key}-nat-gw"
  }
}

# Private Route Table
resource "aws_route_table" "private" {
  for_each = var.deployment_regions

  vpc_id = aws_vpc.main[each.key].id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }

  tags = {
    Name = "${each.key}-private-route"
  }
}
