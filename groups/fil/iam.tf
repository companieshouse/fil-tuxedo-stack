module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.62"
  name   = "${var.service_subtype}-${var.service}-profile"

  cw_log_group_arns = [for log_group in merge(aws_cloudwatch_log_group.tuxedo, { "cloudwatch" = aws_cloudwatch_log_group.cloudwatch }) : log_group.arn]
  enable_SSM        = true
  kms_key_refs      = local.instance_profile_kms_key_access_ids
  s3_buckets_write  = local.instance_profile_writable_buckets
}
