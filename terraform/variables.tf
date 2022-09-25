variable "environment" {
  type = string
}

locals {
  project = "vajeh"
  tier    = "frontend"
}

locals {
  service = "app"
  name_prefix = "${local.project}-${local.service}-${var.environment}"
}

locals {
  root_domain_name = "vajeh.artronics.me.uk"
  domain_name = "${var.environment}.${local.service}.${local.root_domain_name}"
  bucket_name         = local.domain_name
}
