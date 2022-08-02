provider "aws" {
  region  = var.region
  version = ">= 3.0.0, < 4.0.0"
}

terraform {
  backend "s3" {
  }
}
