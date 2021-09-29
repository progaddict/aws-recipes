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
    key    = "terraform-state/create-vpc/role"
  }
}

provider "aws" {}

variable "common_tags" {
  type        = map(string)
  description = "Tags which should be applied to all resources."
  default = {
    owner = "alex.ryndin"
    env   = "dev"
  }
}

data "aws_iam_user" "terraform_user" {
  user_name = "AlexTerraformUser"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.terraform_user.arn]
    }
  }
}

data "aws_s3_bucket" "state_s3_bucket" {
  bucket = "alex-misc"
}



resource "aws_iam_policy" "s3_tf_state_access" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = data.aws_s3_bucket.state_s3_bucket.arn
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "${data.aws_s3_bucket.state_s3_bucket.arn}/terraform-state/create-vpc"
      },
    ]
  })
  tags = merge(
    var.common_tags,
    {
      Name = "s3_tf_state_access"
    }
  )
}

resource "aws_iam_user_policy_attachment" "s3_tf_state_access" {
  user       = data.aws_iam_user.terraform_user.user_name
  policy_arn = aws_iam_policy.s3_tf_state_access.arn
}



resource "aws_iam_role" "create_vpc" {
  path               = "/alexryndin/iac/terraform/"
  description        = "Contains necessary access rights to create a VPC."
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = merge(
    var.common_tags,
    {
      Name = "create_vpc"
    }
  )
}

resource "aws_iam_policy" "create_vpc" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # TODO define rights to create VPC
      {
        Effect   = "Allow",
        Action   = ["ec2:StartInstances"],
        Resource = "*"
      },
    ]
  })
  tags = merge(
    var.common_tags,
    {
      Name = "create_vpc"
    }
  )
}

resource "aws_iam_role_policy_attachment" "create_vpc" {
  role       = aws_iam_role.create_vpc.name
  policy_arn = aws_iam_policy.create_vpc.arn
}

output "role_arn" {
  description = "IAM role's ARN."
  value       = aws_iam_role.create_vpc.arn
}
