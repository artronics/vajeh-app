locals {
  project = "vajeh"
  tier    = "frontend"
}

locals {
  environment = terraform.workspace
  service = "app"
  name_prefix = "${local.project}-${local.service}-${local.environment}"
}

locals {
  root_domain_name = "vajeh.artronics.me.uk"
  domain_name = "${local.environment}.${local.service}.${local.root_domain_name}"
  bucket_name         = local.domain_name
}
