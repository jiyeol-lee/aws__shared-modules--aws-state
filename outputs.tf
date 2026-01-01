output "bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.state.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state storage"
  value       = aws_s3_bucket.state.arn
}

output "bucket_region" {
  description = "AWS region where the S3 bucket is located"
  value       = aws_s3_bucket.state.region
}

output "policy_arn" {
  description = "ARN of the IAM policy for Terraform state access"
  value       = aws_iam_policy.terraform_state.arn
}

output "policy_id" {
  description = "ID of the IAM policy for Terraform state access"
  value       = aws_iam_policy.terraform_state.id
}

output "lifecycle_rule_id" {
  description = "ID of the S3 lifecycle rule for noncurrent version expiration. Returns null when lifecycle management is disabled."
  value       = try(aws_s3_bucket_lifecycle_configuration.state[0].rule[0].id, null)
}
