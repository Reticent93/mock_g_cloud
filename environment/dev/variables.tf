  variable "oidc_provider_arn" {
    description = "ARN for the IAM OIDC role"
    type        = string
  }

  variable "repo_owner" {
    description = "Owner of the repository."
    type        = string
  }

  variable "repo_name" {
    description = "Name of the repository."
    type        = string
  }

  variable "aws_region" {
    description = "AWS region to launch servers."
    type = string
    default = "us-west-2"
  }

  variable "state_bucket_name" {
    description = "Name of S3 bucket to store Terraform state files"
    type        = string
  }

  variable "create_deploy_role" {
    description = "Controls whether an IAM role should be created"
    type        = bool
    default     = false
  }

  variable "deploy_role_name" {
    description = "Name of the IAM role GitHub deployment will assume"
    type        = string
    default     = "GitHub_Actions_Deploy_Role_DEV"
  }

  variable "project_name" {
    description = "Name of the project"
    type        = string
  }

  variable "vpc_cidr" {
    description = "CIDR for VPC"
    type        = string
  }

  variable "flow_log_retention" {
    description = "Number of days to keep cloudwatch flow logs"
    type        = string
    default     = "7"
  }
