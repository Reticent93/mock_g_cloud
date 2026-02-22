# ☁️ Mock G-Cloud

> Production-grade, three-tier AWS infrastructure deployed with Terraform and GitHub Actions.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Checkov](https://img.shields.io/badge/Checkov-Passing-4CAF50?style=for-the-badge&logo=checkmarx&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

---

## 🏗️ Architecture

A classic three-tier design for high availability and security isolation across multiple AWS Availability Zones.

```
                        ┌─────────────────────────────────────┐
                        │              Internet                │
                        └──────────────────┬──────────────────┘
                                           │
                        ┌──────────────────▼──────────────────┐
                        │      Application Load Balancer       │
                        │         (Public Subnets)             │
                        └──────────┬──────────────┬───────────┘
                                   │              │
               ┌───────────────────▼──────────────▼───────────────────┐
               │               WEB TIER  (EC2 + ASG)                  │
               │              Apache — Private Subnets                 │
               └───────────────────────────┬───────────────────────────┘
                                           │
               ┌───────────────────────────▼───────────────────────────┐
               │             DATA TIER  (Amazon RDS)                   │
               │          PostgreSQL — Dedicated Private Subnets        │
               └───────────────────────────────────────────────────────┘

          VPC │ Public + Private Subnets │ Multi-AZ │ Secrets Manager │ CloudWatch
```

| Tier | Service | Details |
|------|---------|---------|
| **Web** | EC2 + ALB | Auto Scaling Group behind an Application Load Balancer |
| **App** | EC2 | Apache + PostgreSQL client, isolated in private subnets |
| **Data** | RDS | Highly available PostgreSQL in dedicated private subnets |
| **Network** | VPC | Segmented public/private subnets across multiple AZs |

---

## 🛡️ Security

| Feature | Implementation |
|---------|----------------|
| **Identity Federation** | OIDC eliminates static IAM credentials — GitHub Actions authenticates with AWS via short-lived tokens |
| **Least Privilege IAM** | Custom-scoped policies for the deployment runner and all EC2 instances |
| **Secret Management** | AWS Secrets Manager injects DB credentials at runtime via EC2 User Data — nothing sensitive lives in the repo |
| **Static Analysis** | Checkov scans all Terraform files for misconfigurations before any deployment |
| **Centralized Logging** | CloudWatch Agent streams Apache access logs and DB connectivity tests for persistent observability |

---

## 🚀 CI/CD Pipeline

Every push to `main` triggers a fully automated, security-first deployment:

```
Push to main
     │
     ▼
┌─────────────┐     ┌──────────────────┐     ┌───────────────────┐
│  🔍 Checkov  │────▶│ 📋 Terraform Plan │────▶│ ✅ Terraform Apply │
│ Security Scan│     │  Preview Changes  │     │  Deploy via OIDC  │
└─────────────┘     └──────────────────┘     └───────────────────┘
```

---

## 🛠️ Tech Stack

| Category | Tools |
|----------|-------|
| **IaC** | Terraform |
| **Cloud** | AWS — VPC, EC2, ALB, RDS, IAM, Secrets Manager, CloudWatch |
| **CI/CD** | GitHub Actions |
| **Security** | OIDC, Checkov |
| **Runtime** | Apache (httpd), PostgreSQL Client |

---

## 📖 Getting Started

### Prerequisites
- AWS account with an [OIDC provider configured for GitHub](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- Terraform >= 1.0
- AWS CLI configured locally (for manual runs)

### Deploy

```bash
# 1. Clone the repo
git clone https://github.com/Reticent93/mock_g_cloud.git
cd mock_g_cloud

# 2. Set your project variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your configuration

# 3. Push to main to trigger the pipeline
git push origin main
```

The GitHub Actions workflow handles the rest — scanning, planning, and applying automatically.

---

## 📁 Project Structure

```
mock_g_cloud/
├── .github/
│   └── workflows/       # GitHub Actions pipeline definitions
├── environment/         # Environment-specific variable configs
├── modules/             # Reusable Terraform modules
├── check_region.sh      # Region validation script
└── index.js             # Utility helper script
```