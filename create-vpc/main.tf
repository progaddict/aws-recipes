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
    key    = "terraform-state/create-vpc"
  }
}

provider "aws" {
  assume_role {
    role_arn = var.terraform_role_arn
  }
  default_tags {
    tags = var.common_tags
  }
}

data "aws_availability_zones" "azs" {
  state = "available"
}

locals {
  az_names = slice(data.aws_availability_zones.azs.names, 0, 3)
}

########################################
# VPC AND SUBNETS
########################################
# https://aws.amazon.com/blogs/architecture/one-to-many-evolving-vpc-design/
# https://datatracker.ietf.org/doc/html/rfc1918#section-3
# https://www.davidc.net/sites/default/subnets/subnets.html?network=192.168.0.0&mask=16&division=23.f31990

resource "aws_vpc" "vpc" {
  cidr_block                       = var.vpc_cidr_block
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "Alex VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  # "192.168.0.0/22", "192.168.4.0/22", "192.168.8.0/22"
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 6, count.index)
  availability_zone = local.az_names[count.index]
  tags = {
    Name = "Alex Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  # "192.168.16.0/20", "192.168.32.0/20", "192.168.48.0/20"
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 1)
  availability_zone = local.az_names[count.index]
  tags = {
    Name = "Alex Private Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "lambda_subnet" {
  count  = 3
  vpc_id = aws_vpc.vpc.id
  # "192.168.64.0/20", "192.168.80.0/20", "192.168.96.0/20"
  cidr_block        = cidrsubnet(var.vpc_cidr_block, 4, count.index + 4)
  availability_zone = local.az_names[count.index]
  tags = {
    Name = "Alex Lambda Subnet ${count.index + 1}"
  }
}

########################################
# ROUTING
########################################

resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route                  = []
  tags = {
    Name = "Alex Default Route Table"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Alex Internet Gateway"
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Alex Route Table For Public Subnets"
  }
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
  count          = 3
  route_table_id = aws_route_table.public_subnet_route_table.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

########################################
# SECURITY GROUPS
########################################

resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.vpc.id
  # block all trafic by default
  # and discourage thus usage of
  # default SG because being explicit
  # about SGs is generally preferred
  ingress = []
  egress  = []
  tags = {
    Name = "Alex VPC's Default Security Group"
  }
}

resource "aws_security_group" "public_subnet_sg" {
  name        = "public_subnet_sg"
  description = "Allow inbound TLS traffic."
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "Alex Public Subnet Security Group"
  }
}

resource "aws_security_group" "private_subnet_sg" {
  name        = "private_subnet_sg"
  description = "Allow traffic from public subnet."
  vpc_id      = aws_vpc.vpc.id
  tags = {
    Name = "Alex Private Subnet Security Group"
  }
}

resource "aws_security_group_rule" "public_subnet_sg_allow_inbound_tls" {
  # Internet ---> public subnet SG
  security_group_id = aws_security_group.public_subnet_sg.id
  type              = "ingress"
  description       = "Allow TLS."
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "public_subnet_sg_allow_outbound_private" {
  # public subnet SG ---> private subnet SG
  security_group_id        = aws_security_group.public_subnet_sg.id
  type                     = "egress"
  description              = "Allow traffic to private subnets."
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1" # All
  source_security_group_id = aws_security_group.private_subnet_sg.id
}

resource "aws_security_group_rule" "private_subnet_sg_allow_inbound_public" {
  # public subnet SG ---> private subnet SG
  security_group_id        = aws_security_group.private_subnet_sg.id
  type                     = "ingress"
  description              = "Allow traffic to private subnets."
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1" # All
  source_security_group_id = aws_security_group.public_subnet_sg.id
}

resource "aws_security_group_rule" "private_subnet_sg_allow_outbound_private" {
  # private subnet SG ---> private subnet SG
  security_group_id = aws_security_group.private_subnet_sg.id
  type              = "egress"
  description       = "Allow traffic to private subnets."
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # All
  self              = true
}
