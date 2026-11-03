output "state_bucket" {
  description = "Put this in infra/backend.tf and the TF_STATE_BUCKET repository variable."
  value       = aws_s3_bucket.state.bucket
}

output "github_deploy_role_arn" {
  description = "Put this in the AWS_ROLE_ARN repository variable."
  value       = aws_iam_role.github_deploy.arn
}
