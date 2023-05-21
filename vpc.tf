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

# VPC
# create a vpc
resource "aws_vpc" "go-simple-api" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "go-api-vpc"
  }
}

# create a public subnet
resource "aws_subnet" "go-simple-public-subnet1" {
  vpc_id                  = aws_vpc.go-simple-api.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "go-api-subnet-public-1"
  }
}

# create a private subnet
resource "aws_subnet" "go-simple-private-subnet1" {
  vpc_id            = aws_vpc.go-simple-api.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1a"
  tags = {
    Name = "go-api-subnet-private-1"
  }
}

# create an internet gateway
resource "aws_internet_gateway" "go-simple-api-igt" {
  vpc_id = aws_vpc.go-simple-api.id
  tags = {
    Name = "go-internet-gateway"
  }
}

resource "aws_network_acl" "go-simple-public-network-acl" {
  vpc_id = aws_vpc.go-simple-api.id

  ingress {
    protocol   = "-1"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    protocol   = "-1"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # TODO: check if it is possible to remove, because all ports are open in above setting 
  ingress {
    protocol   = "6" # TCP protocol
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "6" # TCP protocol
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  # TODO: check if it is possible to remove, because all ports are open in above setting 

  ingress {
    protocol   = "6" # TCP
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  egress {
    protocol   = "6" # TCP
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

}

resource "aws_network_acl_association" "example" {
  subnet_id      = aws_subnet.go-simple-public-subnet1.id
  network_acl_id = aws_network_acl.go-simple-public-network-acl.id
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




# security group
resource "aws_security_group" "go-simple-api-security-group" {
  name        = "go-web-access"
  description = "allow inbound and outbound for web access"
  vpc_id      = aws_vpc.go-simple-api.id

  # ingress {
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from any IP address (not recommended for production)
  # }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # egress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# create key-pair for ssh connection
resource "aws_key_pair" "go-simple-api-deployer" {
  key_name   = "deployer-key-pair"
  public_key = "replace by public key"
}


# ec2 instance
resource "aws_instance" "go-simple-api" {
  ami                         = "ami-04e601abe3e1a910f"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.go-simple-public-subnet1.id
  vpc_security_group_ids      = [aws_security_group.go-simple-api-security-group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.go-simple-api-deployer.key_name
}


output "vpc_id" {
  value = aws_vpc.go-simple-api.id
}

output "instance_ip" {
  value = aws_instance.go-simple-api.public_ip
}

# TODO:
# 1. separate terraform
# 2. env
# 3. http -> https
# 4. 3000 -> 80
# 5. separate terraform
# 6. DB
