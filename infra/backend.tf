# Remote state in S3 with native S3 state locking (Terraform 1.10+).
# Replace the bucket with the "state_bucket" output from bootstrap/.
# CI overrides it with: terraform init -backend-config="bucket=$TF_STATE_BUCKET"
terraform {
  backend "s3" {
    bucket       = "REPLACE_WITH_STATE_BUCKET"
    key          = "eks-platform/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
