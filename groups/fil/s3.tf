resource "aws_s3_bucket" "ef_presenter_data" {
  count = local.ef_presenter_data_count

  bucket = local.ef_presenter_data_bucket_name
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ef_presenter_data" {
  count = local.ef_presenter_data_count

  bucket = aws_s3_bucket.ef_presenter_data[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.fil[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "ef_presenter_data" {
  count = local.ef_presenter_data_count

  bucket = aws_s3_bucket.ef_presenter_data[0].id
  policy = data.aws_iam_policy_document.ef_presenter_data_bucket[0].json
}

resource "aws_s3_bucket_lifecycle_configuration" "ef_presenter_data" {
  count = local.ef_presenter_data_count

  bucket = aws_s3_bucket.ef_presenter_data[0].id

  rule {
    id = "ef-presenter-data-expiration"

    filter {}

    expiration {
      days = 14
    }

    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ef_presenter_data" {
  count = local.ef_presenter_data_count

  bucket = aws_s3_bucket.ef_presenter_data[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

module "s3_access_logging" {
  source = "git@github.com:companieshouse/terraform-modules//aws/s3_access_logging?ref=tags/1.0.262"

  aws_account         = var.aws_account
  aws_region          = var.region
  source_s3_bucket_id = aws_s3_bucket.ef_presenter_data.id
}
