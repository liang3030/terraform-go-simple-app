terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}

# create a vpc
resource "aws_vpc" "go-simple-api" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "go-api-vpc"
  }
}

# create a public subnet
resource "aws_subnet" "go-simple-public-subnet1" {
  vpc_id            = aws_vpc.go-simple-api.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "go-api-subnet-public-1"
  }
}

# create a private subnet
resource "aws_subnet" "go-simple-private-subnet1" {
  vpc_id            = aws_vpc.go-simple-api.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "go-api-subnet-private-1"
  }
}

# create a public route table
resource "aws_route_table" "go-simple-public-route-table" {
  vpc_id = aws_vpc.go-simple-api.id
  tags = {
    Name = "go-api-public-route-table"
  }
}

# create a private route table
resource "aws_route_table" "go-simple-private-route-table" {
  vpc_id = aws_vpc.go-simple-api.id
  tags = {
    Name = "go-api-private-route-table"
  }
}

# create an internet gateway
resource "aws_internet_gateway" "go-simple-api-igt" {
  vpc_id = aws_vpc.go-simple-api.id
  tags = {
    Name = "go-internet-gateway"
  }
}

resource "aws_route" "go-simple-api-public-route" {
  route_table_id         = aws_route_table.go-simple-public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.go-simple-api-igt.id
}

# resource "aws_route" "go-simple-api-private-route" {
#   route_table_id         = aws_route_table.go-simple-private-route-table.id
#   destination_cidr_block = "0.0.0.0/0"
# }

# associate subnet with route table
resource "aws_route_table_association" "go-simple-api-public-route-table-ass" {
  route_table_id = aws_route_table.go-simple-public-route-table.id
  subnet_id      = aws_subnet.go-simple-public-subnet1.id
}

resource "aws_route_table_association" "go-simple-api-private-route-table-ass" {
  route_table_id = aws_route_table.go-simple-private-route-table.id
  subnet_id      = aws_subnet.go-simple-private-subnet1.id
}
