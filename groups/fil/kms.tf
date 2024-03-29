
resource "aws_kms_key" "fil" {
  count = local.ef_presenter_data_count

  description         = "KMS key for FIL Tuxedo services"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.fil[0].json

  tags = merge(local.common_tags, {
    Name = local.common_resource_name
  })
}

resource "aws_kms_alias" "fil" {
  count = local.ef_presenter_data_count

  name          = "alias/${local.common_resource_name}"
  target_key_id = aws_kms_key.fil[0].key_id
}
