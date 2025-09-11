output "public_dns_name" {
  value = aws_lb.web_lb.dns_name
}

output "id" {
  value = aws_lb.web_lb.id
  
}