output "user_arn" {
  description = "ARN of the terraform IAM user."
  value       = aws_iam_user.alex_terraform_user.arn
}
