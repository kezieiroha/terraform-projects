# Terraform Labs

This repository contains my personal Terraform projects and infrastructure automation labs. It serves as a hands-on environment for exploring Terraform best practices, cloud automation, and infrastructure as code (IaC).

---

## **Project Structure**
Each directory in this repository represents a separate Terraform lab or module.

### **1. AWS-Lab - WIP**
- Deploy AWS 3 tier architecture with dedicated VPC and select CIDR range, DB & app private tier, public web tier, and bastion public subnet across single/multi-region/AZ, with load balancing and auto-scaling, observability
- Deploy flavours of AWS RDS/Aurora database configurations that demonstrate MAA best practices

---

## **Requirements**
To use these Terraform configurations, ensure you have the following installed:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (latest version)
- AWS CLI (`aws configure` for authentication)
- An AWS account with necessary IAM permissions

---

## **Multi-AZ Revisit Branch - Known Issues & Refactoring Notes**

### **Issues Identified:**
1. **Provider Duplication:**
   - **Issue:** Static region and provider alias definitions required in multiple files (`provider.tf`, `main.tf`, `terraform.tfvars`), violating DRY principles.
   - **Example of Non-Working Code:**
     ```hcl
     provider "aws" {
       alias  = "us_east_1"
       region = "us-east-1"
     }

     provider "aws" {
       alias  = "eu_west_1"
       region = "eu-west-1"
     }

     module "vpc" {
       source = "./modules/vpc"
       providers = {
         aws = aws.us_east_1
       }
     }
     ```

2. **Dynamic Provider Limitations:**
   - **Issue:** Terraform does not support dynamic provider alias creation at parse time, leading to hardcoded regions and aliases.
   - **Example of Non-Working Code:**
     ```hcl
     provider "aws" {
       alias  = each.key
       region = each.value
     }
     ```

3. **Complex Conditional Logic:**
   - **Issue:** Complicated `if` conditions in `main.tf` to switch between regions, reducing readability and maintainability.
   - **Example of Non-Working Code:**
     ```hcl
     providers = {
       aws = each.key == "us-east-1" ? aws.us_east_1 : aws.eu_west_1
     }
     ```

4. **Deployment Inconsistencies:**
   - **Issue:** Resources for multiple regions were being deployed in a single region due to improper provider referencing.
   - **Example of Non-Working Code:**
     ```hcl
     resource "aws_instance" "web" {
       ami           = "ami-12345678"
       instance_type = "t2.micro"
       provider      = aws.${var.region}
     }
     ```

### **Refactoring Goals for `multi-az-revisit` Branch:**
- **Reduce Hardcoding:** Centralise region/provider configurations to `terraform.tfvars` where possible.
- **Improve Provider Handling:** Define provider aliases statically in `provider.tf` while referencing them dynamically in modules.
- **Enhance Readability:** Simplify conditional logic and maintain clean, modular code.
- **Ensure Accurate Multi-Region Deployments:** Validate that resources are deployed in their respective regions using correct provider mappings.

---
