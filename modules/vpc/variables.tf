variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "name_suffix" {
  description = "Name suffix for the project"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type = string
}

variable "aws_availability_zones" {
  description = "List of availability zones"
  type = list(string)
}

variable "flow_log_retention" {
  type        = number
  description = "Days to keep logs"
}

variable "flow_log_role_arn" {
  description = "IAM role for flow logs"
  type        = string
}


