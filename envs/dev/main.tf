# CodeSeries : CodePipeline , CodeDeploy 
# Internet Gateway : allow access in VPC level

##----------------------------VPC Level--------------------------
# VPC : define resource group
resource "aws_vpc" "main_vpc" {
  cidr_block           = "172.16.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "web-network",
    project = "accounting-cqrs-project"
  }
}

# Internet Gateway : allow access in VPC level
resource "aws_internet_gateway" "main_igw" {
  vpc_id     = aws_vpc.main_vpc.id
  depends_on = [aws_vpc.main_vpc]
  tags = {
    Name    = "web-network",
    project = "accounting-cqrs-project"
  }
}

# Route Table :
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name    = "web-network",
    project = "accounting-cqrs-project"
  }
}

# Public Table Association : connect EC2 subnet with public route table
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.server_subnet.id
  route_table_id = aws_route_table.public_route.id
}


# RDS Table Association : connect RDS subnet with public route table
resource "aws_route_table_association" "db_subnet1_assoc" {
  subnet_id      = aws_subnet.db_subnet_1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "db_subnet2_assoc" {
  subnet_id      = aws_subnet.db_subnet_2.id
  route_table_id = aws_route_table.public_route.id
}

# Route : connect internet gateway with route table
resource "aws_route" "public_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main_igw.id
  route_table_id         = aws_route_table.public_route.id
}

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
    from_port   = var.command_service_port
    to_port     = var.query_service_port
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

##------------------------RDS Instance---------------------------

# DB Subnet Group : 2 or more subnets in different AZ
resource "aws_db_subnet_group" "my_db_subnet_group" {
  subnet_ids = [
    aws_subnet.db_subnet_1.id,
    aws_subnet.db_subnet_2.id
  ]
  depends_on = [aws_vpc.main_vpc]

  tags = {
    Name    = "web-db",
    project = "accounting-cqrs-project"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Add depends_on to ensure VPC exists before creating subnet
resource "aws_subnet" "db_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name    = "web-db",
    project = "accounting-cqrs-project"
  }
}

# Add depends_on to ensure VPC exists before creating subnet
resource "aws_subnet" "db_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "172.16.2.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name    = "web-db",
    project = "accounting-cqrs-project"
  }
}
# DB_parameter
resource "aws_db_parameter_group" "my_db_parameter_group" {
  description = "Parameter group for web database"
  family      = "postgres17"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  tags = {
    Name    = "web-db-group",
    project = "accounting-cqrs-project"
  }
}

# RDS
resource "aws_db_instance" "web_db" {
  instance_class         = "db.t3.micro"
  engine                 = "postgres"
  engine_version         = "17.4"
  allocated_storage      = 5
  username               = var.db_username
  password               = var.db_password
  db_name                = var.db_schema
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.my_db_parameter_group.name
  publicly_accessible    = true
  skip_final_snapshot    = true

  tags = {
    Name = "web-db",
  project = "accounting-cqrs-project" }
}

# DB Security Group
resource "aws_security_group" "db_sg" {
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Allow DB access from anywhere"
    from_port   = 5432
    to_port     = 5432
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
    Name    = "web-db",
    project = "accounting-cqrs-project"
  }
}

# --------------------Private RDS Setup with AWS CI/CD----------------------------

# AWS CodeBuild
# https://docs.aws.amazon.com/codebuild/latest/userguide/action-runner.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project

# AWS CodeDeploy
# 

# # Private Route Table (No Table Associate)
# resource "aws_route_table" "private_route" {
#   vpc_id = aws_vpc.main_vpc.id

#   tags = {
#     Name    = "private-route"
#     project = "accounting-cqrs-project"
#   }
# }

# Ingress Rules
resource "aws_security_group_rule" "allow_ec2_to_rds" {
  type                     = "ingress"
  description              = "Allow DB access from anywhere web servers"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db_sg.id
  source_security_group_id = aws_security_group.web_sg.id
}