provider "aws" {
  region = var.Region

  default_tags {
    tags = {
      Environment = "workshop"
      Provisioner = "Terraform"
      Solution    = "wildlife"
    }
  }
}