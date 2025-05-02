output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = module.alb_sg.security_group_id
}

output "instance_sg_id" {
  description = "ID of the instance security group"
  value       = module.instance_sg.security_group_id
}