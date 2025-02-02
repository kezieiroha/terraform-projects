# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/outputs.tf
# Author: Kezie Iroha
# Description: outputs for vpc module
# ------------------------------------------------------------------------------

/*
output "vpc_details" {
  description = "Details of the created VPC, including subnets, security groups, and route tables"
  value = {
    vpc_id   = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
    vpc_igw  = aws_internet_gateway.gw.id
    subnets = {
      public_bastion = {
        id         = aws_subnet.public_bastion.id
        cidr_block = aws_subnet.public_bastion.cidr_block
      }
      public_web = {
        id         = aws_subnet.public_web.id
        cidr_block = aws_subnet.public_web.cidr_block
      }
      private_app = {
        id         = aws_subnet.private_app.id
        cidr_block = aws_subnet.private_app.cidr_block
      }
      private_db = {
        id         = aws_subnet.private_db.id
        cidr_block = aws_subnet.private_db.cidr_block
      }
    }
    security_groups = {
      web      = aws_security_group.web.id
      app      = aws_security_group.app.id
      database = aws_security_group.database.id
      bastion  = aws_security_group.bastion.id
    }
  }
}
*/

output "vpc_details" {
  description = "Details of the created VPCs, including subnets and gateways"
  value = {
    for region in keys(var.deployment_regions) :
    region => {
      vpc_id   = aws_vpc.main[region].id
      vpc_cidr = aws_vpc.main[region].cidr_block
      igw_id   = aws_internet_gateway.igw[region].id
      nat_id   = aws_nat_gateway.nat[region].id

      subnets = {
        public  = [for key, s in aws_subnet.public : s.id if startswith(key, "${region}-public")]
        private = [for key, s in aws_subnet.private : s.id if startswith(key, "${region}-private")]
      }
    }
  }
}
