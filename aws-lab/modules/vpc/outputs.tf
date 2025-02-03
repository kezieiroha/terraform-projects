# ------------------------------------------------------------------------------
# Module: vpc
# File: modules/vpc/outputs.tf
# Author: Kezie Iroha
# Description: outputs for vpc module
# ------------------------------------------------------------------------------

output "vpc_details" {
  description = "Details of the created VPCs, including subnets, security groups, and gateways"
  value = {
    for region, config in var.deployment_regions :
    region => {
      vpc_id   = aws_vpc.main[region].id
      vpc_cidr = aws_vpc.main[region].cidr_block
      igw_id   = aws_internet_gateway.igw[region].id
      nat_id   = aws_nat_gateway.nat[region].id

      subnets = {
        public  = [for key, s in aws_subnet.public : s.id if startswith(key, "${region}-public")]
        private = [for key, s in aws_subnet.private : s.id if startswith(key, "${region}-private")]
      }

      security_groups = {
        web      = aws_security_group.web[region].id
        app      = aws_security_group.app[region].id
        database = aws_security_group.database[region].id
        bastion  = aws_security_group.bastion[region].id
      }
    }
  }
}
