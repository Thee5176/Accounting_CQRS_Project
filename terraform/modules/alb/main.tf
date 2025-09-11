# Elastic Load Balancer (ALB)
resource "aws_lb" "web_lb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups    = [module.ec2.security_group_id, module.rds.security_group_id]
  subnets            = [module.vpc.public_subnet_id]

  enable_deletion_protection = true

  tags = {
    Name    = "web-alb",
    project = "accounting-cqrs-project"
  }
}

