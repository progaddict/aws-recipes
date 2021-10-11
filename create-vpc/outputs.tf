output "vpc_id" {
  description = "Created VPC's ID."
  value       = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = aws_subnet.private_subnet[*].id
}

output "lambda_subnet_ids" {
  description = "Lambda subnet IDs."
  value       = aws_subnet.lambda_subnet[*].id
}
