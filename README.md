# ☁️ Mock G-Cloud

> Production-grade, three-tier AWS infrastructure deployed with Terraform and GitHub Actions.

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Checkov](https://img.shields.io/badge/Checkov-Passing-4CAF50?style=for-the-badge&logo=checkmarx&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL_17-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

---

## 📋 Table of Contents

- [Architecture Overview](#-architecture-overview)
- [Terraform Modules](#-terraform-modules)
- [CI/CD Pipeline](#-cicd-pipeline)
- [IAM & Authentication](#-iam--authentication)
- [Networking](#-networking)
- [Security Groups](#-security-groups)
- [Application Layer](#-application-layer)
- [Data Layer](#-data-layer)
- [Encryption (KMS)](#-encryption-kms)
- [Observability](#-observability)
- [State Management](#-state-management)
- [Traffic Flow](#-traffic-flow)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)

---

## 🏗️ Architecture Overview

A three-tier design for high availability and security isolation across multiple AWS Availability Zones.

```
                           ┌──────────────────────┐
                           │       Internet        │
                           └──────────┬───────────┘
                                      │ :80 / :443
                           ┌──────────▼───────────┐
                           │  Application Load     │
                           │  Balancer (ALB)       │  ← Public Subnets (×2 AZ)
                           └──────────┬───────────┘
                                      │ :80 → Target Group
                    ┌─────────────────▼─────────────────┐
                    │       Auto Scaling Group           │
                    │   EC2 (Apache + PG client)         │  ← Private Subnets (×2 AZ)
                    │   min: 1  |  desired: 2  |  max: 3 │    Amazon Linux 2023
                    └─────────────────┬─────────────────┘
                                      │ :5432 (IAM auth, SSL)
                    ┌─────────────────▼─────────────────┐
                    │       RDS PostgreSQL 17            │
                    │   manage_master_user_password      │  ← DB Subnets (×2 AZ)
                    │   storage_encrypted  |  force_ssl  │    publicly_accessible: false
                    └───────────────────────────────────┘

  VPC │ IGW + NAT Gateway │ KMS Encryption │ Secrets Manager │ CloudWatch │ SSM
```

| Tier | Service | Key Details |
|------|---------|-------------|
| **Web** | ALB + EC2 ASG | Load balancer in public subnets; EC2 instances in private subnets only |
| **App** | EC2 (AL2023) | Apache, PostgreSQL client; no public IP; IMDSv2 required |
| **Data** | RDS PostgreSQL 17 | IAM auth, SSL forced, encrypted storage, Secrets Manager managed password |
| **Network** | VPC | Public, private, and DB subnets across 2 AZs; NAT for private egress |

---

## 📦 Terraform Modules

The infrastructure is split into three independently deployable layers, each with its own remote state in S3.

```
environment/dev/
├── base/          →  modules/base          (IAM, OIDC, KMS, roles)
├── network/       →  modules/network       (VPC, subnets, RDS, security groups)
└── app/           →  modules/application   (ALB, EC2, ASG, target group)
```

Each layer reads outputs from the layers below it via `terraform_remote_state`, keeping concerns cleanly separated and enabling independent apply/destroy cycles.

| Module | Responsibilities |
|--------|-----------------|
| **base** | OIDC provider, GitHub Deploy Role, EC2 App Role, RDS Monitoring Role, KMS keys, CloudWatch log groups |
| **network** | VPC, subnets, IGW, NAT Gateway, route tables, security groups, RDS instance, DB subnet group, VPC Flow Logs |
| **application** | ALB, ALB listener, target group, launch template, Auto Scaling Group, EC2 security group |

---

## 🚀 CI/CD Pipeline

Every push to `main` triggers a fully automated, security-first deployment with no static AWS credentials anywhere in the pipeline.

```
┌────────────────┐     ┌───────────────────┐     ┌────────────────────┐
│  🔍  Checkov   │────▶│ 📋 Terraform Plan  │────▶│ ✅ Terraform Apply  │
│  Static Scan   │     │  Preview Changes   │     │  Deploy via OIDC   │
│  All .tf files │     │  Against AWS       │     │  1-hour STS token  │
└────────────────┘     └───────────────────┘     └────────────────────┘
```

- **Checkov** scans all `.tf` files for security misconfigurations. Any violation fails the pipeline. Intentional skips are documented inline with justification (e.g. `CKV_AWS_260` for a public ALB).
- **Terraform Plan** runs against AWS using the GitHub Deploy Role, outputting a full preview of changes.
- **Terraform Apply** executes only after scan and plan pass. Uses a short-lived OIDC token (1-hour max session) — no long-lived credentials stored in GitHub Secrets.

---

## 🔐 IAM & Authentication

### OIDC Identity Federation

GitHub Actions authenticates with AWS via OpenID Connect — eliminating the need for any static IAM access keys.

```
GitHub Actions JWT  →  token.actions.githubusercontent.com  →  AWS STS
                                                                    │
                                                         sts:AssumeRoleWithWebIdentity
                                                                    │
                                                         GitHub Deploy Role (1hr session)
```

The trust policy enforces two conditions:
- `aud`: must equal `sts.amazonaws.com`
- `sub`: must match `repo:Reticent93/mock_g_cloud*`

### IAM Roles

| Role | Principal | Purpose |
|------|-----------|---------|
| **GitHub Deploy Role** | `token.actions.githubusercontent.com` (OIDC) | Runs Terraform — scoped to S3 state, DynamoDB lock, and read-only discovery for EC2/RDS/IAM/ELB/KMS |
| **EC2 App Role** | `ec2.amazonaws.com` | Grants EC2 instances access to Secrets Manager (`rds!db-*` ARN only), CloudWatch Agent, and SSM |
| **RDS Monitoring Role** | `monitoring.rds.amazonaws.com` | Enhanced Monitoring via `AmazonRDSEnhancedMonitoringRole` managed policy |
| **VPC Flow Log Role** | `vpc-flow-logs.amazonaws.com` | Write-only access to the specific CloudWatch log group ARN |

### EC2 Instance Policies (App Role)

| Policy | Scope |
|--------|-------|
| `secretsmanager:GetSecretValue` | `rds!db-*` ARN only — DB password at boot |
| `CloudWatchAgentServerPolicy` | AWS managed — ships logs and metrics |
| `AmazonSSMManagedInstanceCore` | AWS managed — SSM Session Manager access |
| `rds-db:connect` | Specific DB resource ID and user — IAM DB auth |

---

## 🌐 Networking

### VPC Layout

```
VPC (configurable CIDR)
│
├── Public Subnets  ×2 AZ  ──  ALB, NAT Gateway
│   └── Route: 0.0.0.0/0 → Internet Gateway
│
├── Private Subnets ×2 AZ  ──  EC2 Auto Scaling Group
│   └── Route: 0.0.0.0/0 → NAT Gateway
│
└── DB Subnets      ×2 AZ  ──  RDS PostgreSQL
    └── Route: 0.0.0.0/0 → NAT Gateway
```

### Key Resources

| Resource | Detail |
|----------|--------|
| **Internet Gateway** | Attached to VPC; public subnets route `0.0.0.0/0` here |
| **NAT Gateway + EIP** | Sits in `public-1`; private and DB subnets egress via NAT |
| **Public Route Table** | `0.0.0.0/0 → IGW` — associated with `Type=public` subnets |
| **Private Route Table** | `0.0.0.0/0 → NAT` — associated with `Type=private` and `Type=db` subnets |
| **VPC Flow Logs** | Captures ALL traffic (ACCEPT + REJECT); shipped to CloudWatch, encrypted by KMS |

EC2 instances have `associate_public_ip_address = false` — they are never directly reachable from the internet.

---

## 🛡️ Security Groups

Traffic is restricted by security group reference (not CIDR) wherever possible, preventing lateral movement between tiers.

```
Internet
   │ :80, :443
   ▼
[ALB-SG]  ──────────────────────────────────────────────────────────────
   │ :80 (referenced by SG ID, not 0.0.0.0/0)
   ▼
[App-SG]  ──────────────────────────────────────────────────────────────
   │ :5432 (referenced by SG ID)               :443 → 0.0.0.0/0 (updates)
   ▼
[DB-SG]
```

| Security Group | Inbound | Outbound |
|---------------|---------|----------|
| **ALB-SG** | `:80` from `0.0.0.0/0`, `:443` from `0.0.0.0/0` | ALB-managed |
| **App-SG** | `:80` from ALB-SG only | `:5432` to DB-SG, `:443` to `0.0.0.0/0` |
| **DB-SG** | `:5432` from App-SG only | None defined |

---

## ⚙️ Application Layer

### Launch Template

| Setting | Value |
|---------|-------|
| AMI | Amazon Linux 2023 (`al2023-ami-*-x86_64`, latest) |
| IMDSv2 | Required (`http_tokens = required`, hop limit 1) |
| Public IP | `false` — no direct internet exposure |
| User Data | Fetches DB secret from Secrets Manager at boot; configures Apache and CloudWatch Agent |

### Auto Scaling Group

| Setting | Value |
|---------|-------|
| Desired capacity | 2 |
| Min / Max | 1 / 3 |
| Health check | ELB (grace period: 300s) |
| Instance refresh | Rolling — minimum 50% healthy |
| Subnets | Private subnets across both AZs |

### Application Load Balancer

| Setting | Value |
|---------|-------|
| Subnets | Public subnets (×2 AZ) |
| Protocol | HTTP :80 → forwards to target group |
| `drop_invalid_header_fields` | `true` |
| Target group health check | `GET /` → HTTP 200; healthy: 2, unhealthy: 6 |

> **Note:** HTTPS redirect is prepared but commented out — a certificate is required for production.

---

## 🗄️ Data Layer

### RDS PostgreSQL 17

| Setting | Value |
|---------|-------|
| Engine | PostgreSQL 17 |
| `publicly_accessible` | `false` |
| `storage_encrypted` | `true` |
| `iam_database_authentication_enabled` | `true` |
| `manage_master_user_password` | `true` (Secrets Manager auto-rotation) |
| `performance_insights_enabled` | `true` |
| `monitoring_interval` | 60 seconds (Enhanced Monitoring) |
| `multi_az` | Configurable via variable (disabled in dev to minimize cost) |
| CloudWatch log exports | `postgresql`, `upgrade` |

### Parameter Group (postgres17)

| Parameter | Value | Effect |
|-----------|-------|--------|
| `rds.force_ssl` | `1` | All connections must use SSL |
| `log_connections` | `1` | Every connection is logged |
| `log_min_duration_statement` | `1000ms` | Slow query logging |

### Secret Management

The RDS master password is managed automatically by AWS (`manage_master_user_password = true`). The secret ARN (pattern: `rds!db-*`) is passed to EC2 User Data at boot. The EC2 App Role has `secretsmanager:GetSecretValue` scoped to this exact ARN prefix — no wildcard access.

---

## 🔑 Encryption (KMS)

Two KMS keys are provisioned with key rotation enabled:

| Key | Encrypts | Rotation | Deletion Window |
|-----|----------|----------|----------------|
| **Flow Log Key** (network module) | VPC Flow Log CloudWatch log group | Enabled | 7 days |
| **CloudWatch Key** (base module) | CloudWatch log groups | Enabled | 30 days |

Both key policies follow the principle of least privilege:
- Root account retains full administrative access
- CloudWatch Logs service is granted encrypt/decrypt via a condition scoped to the specific log group ARN
- GitHub Deploy Role is granted key management permissions for CI/CD operations

---

## 📊 Observability

| Component | What it captures | Destination |
|-----------|-----------------|-------------|
| **VPC Flow Logs** | ALL traffic (ACCEPT + REJECT) across the VPC | CloudWatch Logs (KMS encrypted) |
| **CloudWatch Agent** | Apache access logs from EC2 instances | CloudWatch Logs |
| **RDS PostgreSQL logs** | Connections, slow queries (>1s), upgrades | CloudWatch Logs |
| **RDS Performance Insights** | Query-level DB performance | RDS console |
| **RDS Enhanced Monitoring** | OS-level metrics at 60s intervals | CloudWatch |

### SSM Session Manager

`AmazonSSMManagedInstanceCore` is attached to the EC2 App Role, enabling shell access via SSM Session Manager. This means:
- No SSH port open on any security group
- No bastion host required
- All session activity is logged to CloudWatch

---

## 🪣 State Management

Terraform state is stored remotely in S3 with DynamoDB locking to prevent concurrent runs from corrupting state.

| Layer | S3 Key |
|-------|--------|
| base | `environment/dev/base/terraform.tfstate` |
| network | `environment/dev/network/terraform.tfstate` |
| app | `environment/dev/app/terraform.tfstate` |

Each layer reads outputs from layers below it using `terraform_remote_state`. The GitHub Deploy Role has scoped S3 permissions limited to the specific state bucket ARN.

---

## 🔁 Traffic Flow

```
Internet → ALB (:80/:443)
         → EC2 ASG (:80, from ALB-SG only)
         → RDS (:5432, IAM auth + SSL, from App-SG only)

EC2 boot → Secrets Manager (User Data fetches DB secret)
EC2      → NAT → Internet (:443, OS/package updates)
VPC      → CloudWatch (Flow Logs, KMS encrypted)
EC2      → CloudWatch (Apache logs via CloudWatch Agent)
RDS      → CloudWatch (postgresql + upgrade logs)
```

---

## 🛠️ Tech Stack

| Category | Tools |
|----------|-------|
| **IaC** | Terraform |
| **Cloud** | AWS — VPC, EC2, ALB, ASG, RDS, IAM, KMS, Secrets Manager, CloudWatch, SSM, DynamoDB |
| **CI/CD** | GitHub Actions |
| **Security** | OIDC, IMDSv2, Checkov, KMS, security group isolation |
| **Runtime** | Apache (httpd), PostgreSQL 17 client |
| **OS** | Amazon Linux 2023 |

---

## 📖 Getting Started

### Prerequisites

- AWS account with billing enabled
- [OIDC provider configured for GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- Terraform >= 1.0
- AWS CLI configured locally (for manual inspection)

### Deploy

Layers must be deployed in order — each depends on outputs from the previous.

```bash
# 1. Clone the repo
git clone https://github.com/Reticent93/mock_g_cloud.git
cd mock_g_cloud

# 2. Configure variables for your environment
cp environment/dev/base/terraform.tfvars.example environment/dev/base/terraform.tfvars
# Repeat for network/ and app/ — update account ID, region, bucket name, etc.

# 3. Deploy base layer (IAM, OIDC, KMS)
cd environment/dev/base
terraform init && terraform apply

# 4. Deploy network layer (VPC, RDS, security groups)
cd ../network
terraform init && terraform apply

# 5. Deploy application layer (ALB, EC2, ASG)
cd ../app
terraform init && terraform apply
```

Once the base layer is deployed and the GitHub Deploy Role exists, subsequent deployments happen automatically via the CI/CD pipeline on push to `main`.

---

## 📁 Project Structure

```
mock_g_cloud/
├── .github/
│   └── workflows/              # GitHub Actions — Checkov, plan, apply
├── environment/
│   └── dev/
│       ├── base/               # Layer 1: IAM, OIDC, KMS
│       ├── network/            # Layer 2: VPC, RDS, subnets, SGs
│       └── app/                # Layer 3: ALB, EC2, ASG
├── modules/
│   ├── base/                   # Reusable base module
│   ├── network/                # Reusable network + database module
│   └── application/            # Reusable application module
│       └── user_data.sh        # EC2 boot script (Apache, CW Agent, secret fetch)
├── check_region.sh             # Validates AWS region before apply
└── index.js                    # Utility helper
```