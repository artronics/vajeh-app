data "aws_route53_zone" "project_hosted_zone" {
  name = local.root_domain_name
}

module "s3-static-hosting" {
  source = "./s3-static-hosting"
  providers = {
    aws.main         = aws.main
    aws.acm_provider = aws.acm_provider
  }
  zone_id = data.aws_route53_zone.project_hosted_zone.zone_id

  domain = local.domain_name
  name_prefix = local.name_prefix
  build_path = "${path.root}/../build"
}
