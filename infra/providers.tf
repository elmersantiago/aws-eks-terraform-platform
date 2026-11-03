provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "aws-eks-terraform-platform"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "github.com/elmersantiago/aws-eks-terraform-platform"
    }
  }
}
