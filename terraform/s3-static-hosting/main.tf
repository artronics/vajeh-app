#provider "aws" {
#  aws = aws.main
#  acm_provider = aws.acm_provider
#}

#provider "aws" {
#  alias = "main"
#  region = "eu-west-2"
#
#  default_tags {
#    tags = {
#      project     = "vajeh-frontend"
#      environment = "dev"
#      tier        = "frontend"
#    }
#  }
#}
#
#provider "aws" {
#  alias  = "acm_provider"
#  region = "eu-west-2"
#}
