# EC2
output "ec2_instance_id" {
  description = "EC2 instance id"
  value       = aws_instance.web_server.id
}
output "ec2_instance_public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.web_server.public_ip
}

# DB
output "rds_instance_id" {
  description = "RDS instance id"
  value       = aws_db_instance.web_db.id
}
output "rds_instance_address" {
  description = "RDS instance address"
  value       = aws_db_instance.web_db.address
}
output "rds_endpoint" {
  description = "RDS access endpoint"
  value       = aws_db_instance.web_db.endpoint
}