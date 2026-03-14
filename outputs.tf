output "instance_public_ip" {
  value       = aws_instance.portfolio_instance.public_ip
  description = "Public IP of the EC2 instance"
}

output "instance_id" {
  value       = aws_instance.portfolio_instance.id
  description = "EC2 instance ID"
}

