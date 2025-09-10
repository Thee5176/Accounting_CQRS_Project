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

# Public Subnet : define IP address range based on VPC
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "172.16.1.0/24"
}