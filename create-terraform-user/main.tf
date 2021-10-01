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
    key    = "terraform-state/create-terraform-user"
  }
}

provider "aws" {
  default_tags {
    tags = var.common_tags
  }
}

resource "aws_iam_user" "alex_terraform_user" {
  name          = "AlexTerraformUser"
  path          = "/alexryndin/iac/terraform/"
  force_destroy = true
  tags = {
    Name = "Terra Form"
  }
}
