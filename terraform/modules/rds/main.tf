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
  vpc_id            = module.vpc.aws_vpc.main_vpc.id
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

# DB Security Group
# TODO : port 5432 restrict to ALB's private subnet (restrain the CIDR block)
resource "aws_security_group" "db_sg" {
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = module.vpc.aws_vpc.main_vpc.id

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