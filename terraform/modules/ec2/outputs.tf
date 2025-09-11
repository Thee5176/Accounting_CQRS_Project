# EC2
output "ec2_instance_id" {
  description = "EC2 instance id"
  value       = aws_instance.web_server.id
}
output "ec2_instance_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.web_server.public_ip
}

output "security_group_id" {
  description = "EC2 security group id"
  value       = aws_security_group.web_sg.id
}