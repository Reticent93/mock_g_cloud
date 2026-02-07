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

variable "key_deletion_window" {
  description = "Automatically delete object with days"
  type        = number
}

variable "app_sg" {
  description = "ID of security group for apps"
  type = string
  default = null
}

variable "vpc_id" {
  description = "ID of VPC"
  type = string
}

variable "apps_sg_id" {
  description = "ID of App SG"
  type = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type = list(string)
}

variable "instance_class" {
  description = "The type of DB instance"
  type = string
  default = "db.t3.micro"
}
