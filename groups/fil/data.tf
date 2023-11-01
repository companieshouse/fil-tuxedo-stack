data "aws_caller_identity" "current" {}

data "aws_iam_roles" "sso_administrator" {
  name_regex  = "AWSReservedSSO_AdministratorAccess.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/${var.region}"
}

data "aws_iam_user" "concourse" {
  user_name = "concourse-platform"
}

data "aws_iam_policy_document" "fil" {
  count = local.ef_presenter_data_count

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

  statement {
    sid = "AllowDecryptionOperationsForThesePrincipals"

    principals {
      type        = "AWS"
      identifiers = local.ef_presenter_data_bucket_read_only_principals
    }

    actions = ["kms:Decrypt"]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ef_presenter_data_bucket" {
  count = local.ef_presenter_data_count

  statement {
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

  statement {
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

data "aws_route53_zone" "fil" {
  name   = local.dns_zone
  vpc_id = data.aws_vpc.heritage.id
}

data "aws_vpc" "heritage" {
  filter {
    name   = "tag:Name"
    values = ["vpc-heritage-${var.environment}"]
  }
}

data "vault_generic_secret" "internal_cidrs" {
  path = "aws-accounts/network/internal_cidr_ranges"
}

data "aws_subnets" "application" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.heritage.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.application_subnet_pattern]
  }
}

data "aws_subnet" "application" {
  count = length(data.aws_subnets.application.ids)
  id    = tolist(data.aws_subnets.application.ids)[count.index]
}

data "aws_ami" "fil_tuxedo" {
  owners      = [var.ami_owner_id]
  most_recent = true
  name_regex  = "^${var.service_subtype}-${var.service}-ami-\\d.\\d.\\d"

  filter {
    name   = "name"
    values = ["${var.service_subtype}-${var.service}-ami-${var.ami_version_pattern}"]
  }
}

data "cloudinit_config" "config" {
  count = var.instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud-init/templates/system-config.yml.tpl", {})
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/tnsnames.ora.tpl", {
      tnsnames = jsondecode(data.vault_generic_secret.tns_names.data.tnsnames)
    })
    merge_type = var.user_data_merge_strategy
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/bootstrap-commands.yml.tpl", {
      instance_hostname = "${var.service_subtype}-${var.service}-${var.environment}-${count.index + 1}"
      lvm_block_devices = var.lvm_block_devices
    })
  }
}

data "vault_generic_secret" "kms_keys" {
  path = "aws-accounts/${var.aws_account}/kms"
}

data "vault_generic_secret" "security_s3_buckets" {
  path = "aws-accounts/security/s3"
}

data "vault_generic_secret" "security_kms_keys" {
  path = "aws-accounts/security/kms"
}

data "vault_generic_secret" "tns_names" {
  path = "applications/${var.aws_account}-${var.region}/${var.service_subtype}-${var.service}/tnsnames"
}
data "vault_generic_secret" "ef_presenter" {
  count = local.ef_presenter_data_count

  path = "applications/${var.aws_account}-${var.region}/${var.service_subtype}-${var.service}/ef-presenter"
}
