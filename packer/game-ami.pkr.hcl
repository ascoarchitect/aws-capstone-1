packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
  description = "AWS region to deploy resources"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "project_name" {
  type    = string
  description = "Project name (space-invaders or retro-emulator)"
}

variable "git_repo" {
  type    = string
  description = "Git repository URL to clone"
}

variable "ami_name_prefix" {
  type    = string
  description = "Prefix for the AMI name"
}

locals {
  formatted_name = "${var.ami_name_prefix}-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
}

source "amazon-ebs" "amazon-linux" {
  ami_name      = local.formatted_name
  instance_type = var.instance_type
  region        = var.region
  
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  
  ssh_username = "ec2-user"
  
  tags = {
    Name        = title(var.project_name)
    Environment = "dev"
    Project     = var.project_name
    ManagedBy   = "Packer"
  }
}

build {
  name = var.project_name
  sources = [
    "source.amazon-ebs.amazon-linux"
  ]

  provisioner "shell" {
    environment_vars = [
      "GIT_REPO_URL=${var.git_repo}"
    ]
    script = "scripts/setup.sh"
  }
}