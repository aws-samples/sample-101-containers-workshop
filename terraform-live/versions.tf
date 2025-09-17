terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.10.0"
    }
  }

  backend "s3" {  
    bucket       = "REPLACE_S3_BUCKET_WILDLIFE"
    key          = "terraform/statefile-dev.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}