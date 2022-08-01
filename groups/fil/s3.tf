resource "aws_s3_bucket" "ef_presenter_data" {
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  bucket = local.ef_presenter_data_bucket_name

  # TODO Remove lifecycle block after migration to version 4.x of the Terraform
  # AWS provider; this currently stops plan/apply operations from flip-flopping
  # between adding/removing configuration; see the GitHub issue link for context:
  # https://github.com/hashicorp/terraform-provider-aws/issues/23758
  lifecycle {
    ignore_changes = [
      lifecycle_rule,
      server_side_encryption_configuration
    ]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ef_presenter_data" {
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.ef_presenter_data[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.fil[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "ef_presenter_data" {
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.ef_presenter_data[0].id
  policy = data.aws_iam_policy_document.ef_presenter_data_bucket.json
}

resource "aws_s3_bucket_lifecycle_configuration" "ef_presenter_data" {
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

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
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  bucket = aws_s3_bucket.ef_presenter_data[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
