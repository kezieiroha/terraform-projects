# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/outputs.tf
# Author: Kezie Iroha
# Description: outputs for vpc module
# ------------------------------------------------------------------------------

output "vpc_details" {
  description = "Details of the created VPC, including subnets, security groups, and gateways"
  value = {
    vpc_id   = aws_vpc.main.id
    vpc_cidr = aws_vpc.main.cidr_block
    igw_id   = aws_internet_gateway.igw.id
    nat_id   = aws_nat_gateway.nat.id

    subnets = {
      public  = [for s in aws_subnet.public : s.id]
      private = [for s in aws_subnet.private : s.id]
    }

    security_groups = {
      web      = aws_security_group.web.id
      app      = aws_security_group.app.id
      database = aws_security_group.database.id
      bastion  = aws_security_group.bastion.id
    }
  }
}
