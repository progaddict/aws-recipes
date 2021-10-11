terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "alex-misc"
    key    = "terraform-state/launch-ec2-instances"
  }
}

provider "aws" {
  default_tags {
    tags = var.common_tags
  }
}

data "aws_vpc" "vpc" {
  state = "available"
  tags = {
    Name  = "Alex VPC"
    owner = "alex.ryndin"
    env   = "dev"
  }
}

locals {
  vpc_id = split(":vpc/", data.aws_vpc.vpc.arn)[1]
}

data "aws_subnet" "public_subnet" {
  vpc_id = local.vpc_id
  state  = "available"
  tags = {
    Name  = "Alex Public Subnet 1"
    owner = "alex.ryndin"
    env   = "dev"
  }
}

data "aws_subnet" "private_subnet" {
  vpc_id = local.vpc_id
  state  = "available"
  tags = {
    Name  = "Alex Private Subnet 1"
    owner = "alex.ryndin"
    env   = "dev"
  }
}

data "aws_security_group" "public_subnet_sg" {
  vpc_id = local.vpc_id
  name   = "public_subnet_sg"
}

data "aws_security_group" "private_subnet_sg" {
  vpc_id = local.vpc_id
  name   = "private_subnet_sg"
}

data "aws_ami" "ami" {
  owners      = ["self", "amazon", "aws-marketplace"]
  most_recent = true
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "ena-support"
    values = ["true"]
  }
  filter {
    name   = "is-public"
    values = ["true"]
  }
  filter {
    name   = "name"
    values = ["Fedora-Cloud-Base-34-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "allow_ssh_sg" {
  name        = "allow_ssh_sg"
  description = "Allow inbound SSH traffic."
  vpc_id      = data.aws_vpc.vpc.id
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Alex Security Group Allowing SSH Traffic."
  }
}

resource "aws_security_group" "allow_all_outbound_traffic_sg" {
  name        = "allow_all_outbound_traffic_sg"
  description = "Allow all outbound traffic."
  vpc_id      = data.aws_vpc.vpc.id
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "Alex Security Group Allowing All Outbound Traffic."
  }
}

resource "aws_instance" "public_vm" {
  ami                         = data.aws_ami.ami.id
  associate_public_ip_address = true
  key_name                    = var.ssh_key_name
  subnet_id                   = data.aws_subnet.public_subnet.id
  instance_type               = "t3.nano"
  security_groups = [
    data.aws_security_group.public_subnet_sg.id,
    aws_security_group.allow_ssh_sg.id,
    # for checking connection from VM into public internet
    # e.g. `curl --ipv4 --head https://www.google.com/`
    aws_security_group.allow_all_outbound_traffic_sg.id,
  ]
  tags = {
    Name = "Alex Public Virtual Machine"
  }
}

resource "aws_instance" "private_vm" {
  ami           = data.aws_ami.ami.id
  key_name      = var.ssh_key_name
  subnet_id     = data.aws_subnet.private_subnet.id
  instance_type = "t3.nano"
  security_groups = [
    data.aws_security_group.private_subnet_sg.id,
    aws_security_group.allow_ssh_sg.id,
    # for checking that connection from VM
    # into public internet is not allowed
    # e.g. `curl --ipv4 --head https://www.google.com/` should fail.
    aws_security_group.allow_all_outbound_traffic_sg.id,
  ]
  tags = {
    Name = "Alex Private Virtual Machine"
  }
}
