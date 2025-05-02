# Find latest Space Invaders AMI built by Packer
data "aws_ami" "space_invaders" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["space-invaders-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name   = var.project_name
  environment    = var.environment
  vpc_cidr       = var.vpc_cidr
  azs            = var.azs
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# ALB Module
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security.alb_sg_id
  subnet_ids        = module.vpc.public_subnets
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  instance_type     = var.instance_type
  ami_id            = data.aws_ami.space_invaders.id
  security_group_id = module.security.instance_sg_id
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnets
  target_group_arns = [module.alb.target_group_arn]
  min_size          = var.min_size
  max_size          = var.max_size
  desired_capacity  = var.desired_capacity
}