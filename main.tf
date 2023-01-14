data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 0.12"
}


terraform {
  backend "s3" {
  }
}