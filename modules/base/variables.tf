variable "create_oidc_provider" {
  description = "Controls whether the OIDC provider should be created"
  type        = bool
  default     = false
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "deploy_role_name" {
  description = "Name of the IAM role GitHub deployment will assume"
  type        = string
}

variable "create_deploy_role" {
  description = "Controls whether an IAM role should be created"
  type        = bool
  default     = false
}

variable "state_bucket_name" {
  description = "Name of S3 bucket to store Terraform state files"
  type        = string
}

variable "aws_region" {
  description = "Region to deploy infrastructure into"
  type        = string
  default     = "us-west-2"
}

variable "aws_account_id" {
  description = "The account ID of the current account"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_cloudwatch_log_group" {
  description = "CloudWatch log group that will receive log objects"
  type        = string
}


variable "db_resource_id" {
  description = "resource id for db instance"
  type        = string
}

variable "db_user" {
  description = "Username for the master DB user"
  type        = string
  default     = "dbadmin"
}
