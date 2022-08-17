data "aws_caller_identity" "current" {}

data "aws_iam_roles" "sso_administrator" {
  name_regex  = "AWSReservedSSO_AdministratorAccess.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/${var.region}"
}

data "aws_iam_user" "concourse" {
  user_name = "concourse-platform"
}

data "aws_iam_policy_document" "fil" {
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  statement {
    sid = "EnableIAMPolicies"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid = "AllowAccessForKeyAdministrators"

    principals {
      type        = "AWS"
      identifiers = local.kms_key_administrator_arns
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.ef_presenter_data_bucket_enabled ? [1] : []

    content {
      sid = "AllowDecryptionOperationsForThesePrincipals"

      principals {
        type        = "AWS"
        identifiers = local.ef_presenter_data_bucket_read_only_principals
      }

      actions = ["kms:Decrypt"]

      resources = ["*"]
    }
  }
}

data "aws_iam_policy_document" "ef_presenter_data_bucket" {
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  dynamic "statement" {
    for_each = var.ef_presenter_data_bucket_enabled ? [1] : []

    content {
      sid = "AllowListBucketFromThesePrincipals"

      principals {
        type        = "AWS"
        identifiers = local.ef_presenter_data_bucket_read_only_principals
      }

      actions = [
        "s3:ListBucket"
      ]

      resources = [
        aws_s3_bucket.ef_presenter_data[0].arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.ef_presenter_data_bucket_enabled ? [1] : []

    content {
      sid = "AllowReadAccessFromThesePrincipals"

      principals {
        type        = "AWS"
        identifiers = local.ef_presenter_data_bucket_read_only_principals
      }

      actions = [
        "s3:GetObject",
      ]

      resources = [
        "${aws_s3_bucket.ef_presenter_data[0].arn}/*",
      ]
    }
  }

  statement {
    sid = "DenyPutObjectWithInvalidEncryptionHeader"

    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.ef_presenter_data[0].arn}/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid = "DenyPutObjectWithMissingEncryptionHeader"

    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.ef_presenter_data[0].arn}/*"
    ]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }

  statement {
    sid = "DenyPutObjectWithInvalidEncryptionKeyHeader"

    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.ef_presenter_data[0].arn}/*"
    ]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.fil[0].arn]
    }
  }

  statement {
    sid = "DenyPutObjectWithMissingEncryptionKeyHeader"

    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.ef_presenter_data[0].arn}/*"
    ]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = ["true"]
    }
  }
}
