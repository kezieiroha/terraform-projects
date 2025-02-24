# ------------------------------------------------------------------------------
# Module: kubernetes
# File: modules/kubernetes/outputs.tf
# Author: Kezie Iroha
# Description: outputs for kubernetes module
# ------------------------------------------------------------------------------

output "master_ip" {
  value = aws_instance.master.public_ip
}

output "worker_ip" {
  value = aws_instance.worker.private_ip
}
