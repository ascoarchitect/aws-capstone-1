output "instance_id" {
  description = "ID of the test instance"
  value       = aws_instance.test.id
}

output "public_ip" {
  description = "Public IP of the test instance"
  value       = aws_instance.test.public_ip
}

output "public_dns" {
  description = "Public DNS of the test instance"
  value       = aws_instance.test.public_dns
}