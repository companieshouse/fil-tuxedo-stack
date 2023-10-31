data "aws_route53_zone" "fil" {
  name   = local.dns_zone
  vpc_id = data.aws_vpc.heritage.id
}

resource "aws_route53_record" "instance" {
  count = var.instance_count

  zone_id = data.aws_route53_zone.fil.zone_id
  name    = "instance-${count.index + 1}.${var.service_subtype}.${var.service}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.fil[count.index].private_ip]
}
