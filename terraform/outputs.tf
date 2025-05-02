output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.lb_dns_name
}

output "website_url" {
  description = "URL of the Space Invaders website"
  value       = "http://${module.alb.lb_dns_name}"
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.autoscaling_group_name
}