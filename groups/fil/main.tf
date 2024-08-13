terraform {
  required_version = ">= 1.3"

  backend "s3" {}

  required_providers {
    aws = {
      version = ">= 5.0, < 6.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

####################################################################################################
## S3 access logging
####################################################################################################

module "s3_access_logging" {
  source = "git@github.com:companieshouse/terraform-modules//aws/s3_access_logging?ref=tags/1.0.285"

  count = local.ef_presenter_data_count

  aws_account           = var.aws_account
  aws_region            = var.region
  source_s3_bucket_name = local.ef_presenter_data_bucket_name
}
