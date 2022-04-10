terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
####  CREATİNG VPC #####
resource "aws_vpc" "my_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "my_tf_vpc"
  }
}
#### CREATİNG INTERNET GATEWAY ####
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_tf_gw"
  }
}
#### CREATİNG ROUTE TABLE ####
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "my_f-tf_rt"
  }
}
#### CREATİNG SUBNET ####
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tf_subnet"
  }
}
#### CREATİNG ASSOCIATE ROUTE TABLE ###
resource "aws_route_table_association" "public-test" {
  subnet_id = aws_subnet.subnet1.id                                     
  route_table_id = aws_route_table.r.id
}
#### CREATİNG SEQURIY GROUP ####
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow WEB inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_web"
  }
}
#### CREATING NETWORK INTERFACE ####
resource "aws_network_interface" "web" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.0.0"]
  security_groups = [aws_security_group.allow_web.id]
}
#### CREATİNG ELASTIC IP ####
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web.id
  associate_with_private_ip = "10.0.0.50"
  depends_on = [aws_internet_gateway.gw]
}
#### CREATİNG EC2 INSTANCE ####
resource "aws_instance" "my_firt_tf_instance" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "newpair"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web.id
  }
  user_data = <<EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1.12
              systemctl start nginx
              EOF
  tags = {
    Name = "my_firt_tf_instance"
  }
}
