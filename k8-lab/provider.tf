# ------------------------------------------------------------------------------
# File: provider.tf
# Author: Kezie Iroha
# Description: Providers for project
# ------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
