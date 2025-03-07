# Terraform Labs

This repository contains my personal Terraform projects and infrastructure automation labs. It serves as a hands-on environment for exploring and practising cloud architecture patterns, database configurations, and infrastructure-as-code best practices.

## Usage Permissions

**This code is provided for:**
- Educational purposes
- Portfolio demonstration
- Personal reference

**This code is NOT licensed for:**
- Commercial use without express permission
- Direct implementation in production environments
- Distribution or incorporation into other repositories without attribution

## Professional Notice

If you'd like to collaborate or discuss employment opportunities, please contact me via [LinkedIn](https://www.linkedin.com/in/kezie-i/)

---

## **Project Structure**
Each directory in this repository represents a separate Terraform lab or module.

### **1. AWS-Lab**
- Deploy AWS 3 tier architecture with dedicated VPC and select CIDR range, database & app private tier, public web tier, and bastion public subnet across single/multi-region/AZ, with load balancing and auto scaling, observability
- Deploy flavours of AWS RDS/Aurora database configurations that demonstrate MAA best practices

---

## **Requirements**
**To use these Terraform configurations, ensure you have the following installed:**

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (latest version)
- AWS CLI (`aws configure` for authentication)
- An AWS account with necessary IAM permissions

  **Connect Aurora/RDS:**
   - **Generate an RDS IAM Token from the Bastion Host:**
     ```hcl
     aws rds generate-db-auth-token \
      --hostname <aurora-cluster-endpoint-name> \
      --port 5432 \
      --region us-east-1 \
      --username iam_db_user
     ```

   - **Connect using psql:**
     ```hcl
     PGPASSWORD=$(aws rds generate-db-auth-token \
      --hostname <aurora-cluster-endpoint-name> \
      --port 5432 \
      --region us-east-1 \
      --username iam_db_user) \
      psql "host=<aurora-cluster-endpoint-name> user=iam_db_user dbname=auroradb sslmode=require"
     ```

---

## **Implementation Details**

### **VPC Configuration**
- Multi-AZ networking with public and private subnets
- Secure network isolation through proper security groups
- NAT Gateway for private subnet outbound traffic

### **Bastion Host**
- Secured jump box with SSH or SSM access
- IAM-based authentication to databases
- Automatically configured connection scripts

### **Database Implementation**
- Multiple deployment options (Aurora, Multi-AZ Cluster, Multi-AZ Instance, Single Instance)
- PostgreSQL with automated parameter tuning
- IAM authentication for enhanced security
- High availability across availability zones
- Performance-optimized parameter groups

### **Web & App Tiers**
- Configurable EC2 instance deployment
- Web tier in public subnets
- App tier in private subnets
- Cross-AZ redundancy options

### **Security Features**
- IAM roles with principle of least privilege
- CIDR-restricted SSH access
- TLS key generation and management
- Encrypted storage for all database instances

---

## **Getting Started**

1. Clone this repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and update with your values
3. Run `terraform init` to initialize
4. Run `terraform plan` to verify changes
5. Run `terraform apply` to deploy infrastructure

```
# Example commands
cd aws-lab
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred configuration
terraform init
terraform plan
terraform apply
```

---

© Kezie Christopher Iroha, 2025