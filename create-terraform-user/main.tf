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

provider "aws" {}

resource "aws_iam_user" "alex_terraform_user" {
  name          = "AlexTerraformUser"
  path          = "/alexryndin/iac/terraform/"
  force_destroy = true
  tags = merge(
    var.common_tags,
    {
      Name = "Terra Form"
    }
  )
}
