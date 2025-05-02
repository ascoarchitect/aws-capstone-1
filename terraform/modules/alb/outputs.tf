output "lb_id" {
  description = "ID of the ALB"
  value       = module.alb.lb_id
}

output "lb_arn" {
  description = "ARN of the ALB"
  value       = module.alb.lb_arn
}

output "lb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.lb_dns_name
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_group_arns[0]
}