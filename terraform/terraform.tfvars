# AWS Infrastructure Capstone Project - Custom Variables

# Region configuration
region = "eu-west-1"  # Ireland region

# Project metadata
environment  = "dev" # Environment (dev, test, prod, etc.)

# Network configuration
vpc_cidr        = "10.10.0.0/16" # CIDR block for the VPC
azs             = ["eu-west-1a", "eu-west-1b"] # Availability zones to use
public_subnets  = ["10.10.1.0/24", "10.10.2.0/24"] # CIDR blocks for public subnets
private_subnets = ["10.10.101.0/24", "10.10.102.0/24"] # CIDR blocks for private subnets

# Compute configuration
instance_type    = "t3.micro" # EC2 instance type
min_size         = 1 # Minimum size of the Auto Scaling Group
max_size         = 3 # Maximum size of the Auto Scaling Group
desired_capacity = 2 # Desired capacity of the Auto Scaling Group