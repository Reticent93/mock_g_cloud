variable "project_name" {
  description = "Name of the project"
  type = "string"
}

variable "aws_region" {
  description = "AWS region"
  type = string
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type = list(string)
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type = string
}

variable "aws_availability_zones" {
  description = "List of availability zones"
  type = list(string)
}



