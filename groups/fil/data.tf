data "aws_caller_identity" "current" {}

data "aws_iam_roles" "sso_administrator" {
  name_regex  = "AWSReservedSSO_AdministratorAccess.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/${var.region}"
}

data "aws_iam_user" "concourse" {
  user_name = "concourse-platform"
}

data "aws_iam_policy_document" "fil" {
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
    for_each = var.create_ef_presenter_data_bucket ? [1] : []

    content {
      sid = "AllowDecryptionOperationsForThesePrincipals"

      principals {
        type        = "AWS"
        identifiers = var.ef_presenter_data_read_only_principal_arns
      }

      actions = ["kms:Decrypt"]

      resources = ["*"]
    }
  }
}

data "aws_iam_policy_document" "ef_presenter_data_bucket" {
  dynamic "statement" {
    for_each = var.create_ef_presenter_data_bucket ? [1] : []

    content {
      sid = "AllowListBucketFromThesePrincipals"

      principals {
        type        = "AWS"
        identifiers = var.ef_presenter_data_read_only_principal_arns
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
    for_each = var.create_ef_presenter_data_bucket ? [1] : []

    content {
      sid = "AllowReadAccessFromThesePrincipals"

      principals {
        type        = "AWS"
        identifiers = var.ef_presenter_data_read_only_principal_arns
      }

      actions = [
        "s3:GetObject",
      ]

      resources = [
        "${aws_s3_bucket.ef_presenter_data[0].arn}/*",
      ]
    }
  }
}
