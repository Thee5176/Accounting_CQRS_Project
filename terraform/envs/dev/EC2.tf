##------------------------EC2 Instance---------------------------
# EC2 Subnet : define IP address range based on VPC
resource "aws_subnet" "server_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "172.16.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name    = "web-server",
    project = "accounting-cqrs-project"
  }
}

# EC2
resource "aws_instance" "web_server" {
  ami                         = "ami-000322c84e9ff1be2" #Amazon Linux 2 (ap-ne-1)
  instance_type               = "t2.micro"
  key_name                    = data.aws_key_pair.deployment_key.key_name
  subnet_id                   = aws_subnet.server_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<EOF
    #!/bin/bash
    
    # Update the system
    sudo yum update -y

    # Install Git
    sudo yum install -y git

    # Install Docker and Docker Compose
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -a -G docker ec2-user
    docker --version

    sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version

    # Clone the repository and checkout the docker directory
    git clone https://github.com/Thee5176/SpringBoot_CQRS --no-checkout
    cd SpringBoot_CQRS
    git sparse-checkout set docker react_mui_cqrs --no-cone
  EOF

  tags = {
    Name    = "web-server",
    project = "accounting-cqrs-project"
  }
}

# EC2 Security Group : allow access in instance level
# TODO : port 22, 80, 8181, 8182 restrict to ALB's private subnet (restrain the CIDR block)
resource "aws_security_group" "web_sg" {
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80 # Frontend Port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow incoming data fetch to command service"
    from_port   = 8181 # Command Service Port
    to_port     = 8182 # Query Service Port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "web-server",
    project = "accounting-cqrs-project"
  }
}

# Ingress Rules to access RDS
resource "aws_security_group_rule" "allow_ec2_to_rds" {
  type                     = "ingress"
  description              = "Allow DB access from anywhere web servers"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.web_sg.id
}

# EC2 SSH Key
data "aws_key_pair" "deployment_key" { # Manually created on aws console
  key_name = "github_workflow_key"
  tags = {
    Name    = "web-server",
    project = "accounting-cqrs-project"
  }
}

# # EC2 Elastic IP : Set static IP address
# resource "aws_eip" "web_eip" {
#   instance = aws_instance.web_server.id
#   domain   = "vpc"
#   tags = {
#     Name = "web-server", 
#     project = "accounting-cqrs-project"  }
# }