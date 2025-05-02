module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.0"

  # Auto scaling group
  name = "${var.project_name}-${var.environment}-asg"

  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids

  # Launch template
  launch_template_name        = "${var.project_name}-${var.environment}-lt"
  launch_template_description = "Launch template for ${var.project_name}"
  update_default_version      = true

  image_id          = var.ami_id
  instance_type     = var.instance_type
  security_groups   = [var.security_group_id]
  enable_monitoring = true

  # Target groups to associate with the ASG
  target_group_arns = var.target_group_arns

  # Health check settings
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Instance refresh for zero-downtime deployments
  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-asg"
    Environment = var.environment
    Project     = var.project_name
  }
}