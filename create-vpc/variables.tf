variable "terraform_role_arn" {
  type        = string
  description = "ARN of the IAM role which terraform needs to assume."
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC's CIDR block."
  default     = "192.168.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "Invalid CIDR block."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Tags which should be applied to all resources."
  default = {
    owner = "alex.ryndin"
    env   = "dev"
  }
}
