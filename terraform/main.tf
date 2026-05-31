terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
        source  = "hashicorp/local"
        version = "~> 2.0"
    }

  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "tls_private_key" "hello_world" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content  = tls_private_key.hello_world.private_key_pem
  filename = "${path.module}/private_key.pem"
  # permission
    file_permission = "0600"
}

resource "aws_key_pair" "hello_world" {
  key_name   = "my-key-pair" # Replace with your desired key pair name
  public_key = tls_private_key.hello_world.public_key_openssh
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

output "ami_id" {
  value = data.aws_ami.ubuntu.id
}

resource "aws_security_group" "sg" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name = aws_key_pair.hello_world.key_name
  user_data = file("${path.module}/user_data.sh")
  tags = {
    Name = "HelloWorld"
  }
}

output "instance_id" {
  value = aws_instance.example.id
}

output "ssh_command" {
  value = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.example.public_ip}"
}