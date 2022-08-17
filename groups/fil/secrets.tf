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
  count = var.ef_presenter_data_bucket_enabled ? 1 : 0

  path = "applications/${var.aws_account}-${var.region}/${var.service_subtype}-${var.service}/ef-presenter"
}