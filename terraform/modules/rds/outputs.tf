# DB
output "subnet_group_id_1" {
  description = "RDS subnet group id"
  value       = aws_subnet.db_subnet_1.id
}

output "subnet_group_id_2" {
  description = "RDS subnet group id"
  value       = aws_subnet.db_subnet_2.id
}

output "security_group_id" {
  description = "RDS security group id"
  value       = aws_security_group.db_sg.id
}

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