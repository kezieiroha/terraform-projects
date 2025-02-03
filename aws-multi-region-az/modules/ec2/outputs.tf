# ------------------------------------------------------------------------------
# Module: ec2
# File: modules/ec2/outputs.tf
# Author: Kezie Iroha
# Description: outputs for ec2 module
# ------------------------------------------------------------------------------

output "ec2_instance_ids" {
  description = "IDs of the EC2 instances"
  value = {
    web     = aws_instance.web.id
    db      = aws_instance.db.id
    bastion = aws_instance.bastion.id
  }
}
