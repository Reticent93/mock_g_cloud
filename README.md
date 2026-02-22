☁️ Mock G-Cloud: Automated Three-Tier AWS Infrastructure
An end-to-end, production-grade AWS infrastructure project deployed using Terraform and GitHub Actions. This project demonstrates high availability, secure secret management, and a robust CI/CD pipeline using modern DevSecOps practices.

🏗️ Architecture Overview
The infrastructure follows a classic Three-Tier pattern to ensure maximum security and scalability:

Web Tier: An Application Load Balancer (ALB) manages incoming traffic across an Auto Scaling Group (ASG) of EC2 instances.

Application Tier: EC2 instances running Apache and a PostgreSQL client, isolated in private subnets.

Data Tier: A highly available Amazon RDS (PostgreSQL) instance located in dedicated private subnets.

Networking: A custom VPC with segmented public and private subnets across multiple Availability Zones.

🛡️ DevSecOps & Security Features
Identity Federation (OIDC): Eliminated the risk of static IAM credentials by using OpenID Connect to allow GitHub Actions to authenticate with AWS securely.

Least Privilege IAM: Custom-scoped IAM policies ensure that the deployment runner and EC2 instances have only the exact permissions required.

Secret Orchestration: AWS Secrets Manager is utilized to inject database credentials at runtime via EC2 User Data, ensuring no sensitive information is stored in the repository.

Static Analysis: Integrated Checkov scanning into the CI/CD pipeline to catch infrastructure misconfigurations before they reach production.

Centralized Logging: Configured the CloudWatch Agent to stream system and application logs (Apache access logs and DB connectivity tests) for persistent observability.

🚀 CI/CD Pipeline
The repository uses GitHub Actions for fully automated deployments:

Security Scan: Checkov scans Terraform files for security compliance.

Terraform Plan: Generates an execution plan to preview infrastructure changes.

Terraform Apply: Securely deploys the infrastructure to AWS using short-lived OIDC credentials.

🛠️ Tech Stack
IaC: Terraform

Cloud: AWS (VPC, EC2, ALB, RDS, IAM, Secrets Manager, CloudWatch)

CI/CD: GitHub Actions

Security: OIDC, Checkov

Software: Apache (httpd), PostgreSQL Client

📖 How to Use
Clone the Repo: git clone https://github.com/Reticent93/mock_g_cloud.git

Setup OIDC: Ensure your AWS account has an OIDC provider configured for GitHub.

Variables: Update the terraform.tfvars with your project-specific configurations.

Deploy: Push code to the main branch to trigger the automated GitHub Actions pipeline.