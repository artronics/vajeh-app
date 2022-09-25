resource "aws_route53_record" "root-a" {
  zone_id = var.zone_id
  name    = var.domain
  type    = "A"

  ttl = 300
  records = ["10.10.0.1"]

#  alias {
#    name                   = aws_cloudfront_distribution.root_s3_distribution.domain_name
#    zone_id                = aws_cloudfront_distribution.root_s3_distribution.hosted_zone_id
#    evaluate_target_health = false
#  }
}

#resource "aws_route53_record" "www-a" {
#  zone_id = var.zone_id
#  name    = "www.${var.domain}"
#  type    = "A"
#
#  alias {
#    name                   = aws_cloudfront_distribution.www_s3_distribution.domain_name
#    zone_id                = aws_cloudfront_distribution.www_s3_distribution.hosted_zone_id
#    evaluate_target_health = false
#  }
#}

resource "aws_acm_certificate" "service_certificate" {
  provider                  = aws.acm_provider
  domain_name               = var.domain
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"

#  depends_on = [aws_route53_record.root-a, aws_route53_record.www-a]
  lifecycle {
    create_before_destroy = true
  }
}

//noinspection HILUnresolvedReference
resource "aws_route53_record" "dns_validation" {
  for_each = {
  for dvo in aws_acm_certificate.service_certificate.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
  }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id
}

resource "aws_acm_certificate_validation" "cert_validation_root" {
  provider                = aws.acm_provider
  certificate_arn         = aws_acm_certificate.service_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.dns_validation : record.fqdn]
}
