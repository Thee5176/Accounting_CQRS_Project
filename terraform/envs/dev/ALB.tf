
# --------------------- Application Load Balancer (ALB) ---------------------------

# Application Load Balancer (ALB)
# resource "aws_lb" "web_alb" {
#   name               = "web-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.web_sg.id, aws_security_group.db_sg.id]
#   subnets            = [aws_subnet.public_subnet.id]

#   enable_deletion_protection = true

#   tags = {
#     Name    = "web-alb",
#     project = "accounting-cqrs-project"
#   }
# }