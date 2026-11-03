variable "region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_prefix" {
  description = "Prefix for the state bucket name; the account ID is appended to keep it globally unique."
  type        = string
  default     = "eks-platform-tfstate"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the deploy role, as owner/name."
  type        = string
  default     = "elmersantiago/aws-eks-terraform-platform"
}
