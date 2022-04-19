output "aws_iam_role" {
  description = "ARN of the Prowler IAM role"
  value       = aws_iam_role.prowler_role.arn
}


