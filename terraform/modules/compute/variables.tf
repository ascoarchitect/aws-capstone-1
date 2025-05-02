variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod, etc.)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
}

variable "ami_id" {
  description = "ID of the AMI to use"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for instances"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets for the ASG"
  type        = list(string)
}

variable "target_group_arns" {
  description = "ARNs of the target groups for the ASG"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum size of the ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum size of the ASG"
  type        = number
}

variable "desired_capacity" {
  description = "Desired capacity of the ASG"
  type        = number
}