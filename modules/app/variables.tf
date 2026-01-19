variable "project_name" {
  description = "Name of project"
  type = string
}

variable "vpc_id" {
  description = "ID of VPC"
  type = string
}

variable "public_subnet_ids" {
  description = "IDs of Public Subnets"
  type = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of Private Subnets"
  type = list(string)
}

variable "alb_sg_id" {
  description = "ID of ALB SG"
  type = string
}

variable "apps_sg_id" {
  description = "ID of Apps ALB SG"
}

variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t4g.nano"
}