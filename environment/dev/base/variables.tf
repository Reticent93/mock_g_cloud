variable "repo_owner" {
  type = string
}

variable "repo_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "project_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "create_oidc_provider" {
  type = bool
}

variable "create_deploy_role" {
  type = bool
}

variable "deploy_role_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_resource_id" {
  type = string
}

variable "aws_cloudwatch_log_group" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "kms_key_id" {
  type = string
}



