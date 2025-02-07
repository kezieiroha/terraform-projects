# Terraform Labs

This repository contains my personal Terraform projects and infrastructure automation labs. It serves as a hands-on environment for exploring Terraform best practices, cloud automation, and infrastructure as code (IaC).

---

## **Project Structure**
Each directory in this repository represents a separate Terraform lab or module.

### **1. AWS-Lab - WIP**
- Deploy AWS 3 tier architecture with dedicated vpc and select cidr range, db & app private tier, public web tier, and bastion public subnet across single/multi-region/az, with load balancing and auto scaling, observability
- Deploy flavours of aws rds/aurora database configurations that demonstrate maa best practise


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
      --hostname aurora-cluster-1.cluster-cv244s608wpb.us-east-1.rds.amazonaws.com \
      --port 5432 \
      --region us-east-1 \
      --username iam_db_user
     ```

   - **Connect using psql:**
     ```hcl
     PGPASSWORD=$(aws rds generate-db-auth-token \
      --hostname aurora-cluster-1.cluster-cv244s608wpb.us-east-1.rds.amazonaws.com \
      --port 5432 \
      --region us-east-1 \
      --username iam_db_user) \
      psql "host=aurora-cluster-1.cluster-cv244s608wpb.us-east-1.rds.amazonaws.com user=iam_db_user dbname=auroradb sslmode=require"
     ```

---

