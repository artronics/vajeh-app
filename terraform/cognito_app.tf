locals {
  // FIXME: for now it's only dev env. For other local envs we fallback to dev as well.
  integration_environment = local.environment == "dev" ? "dev" : "dev"
}

data "terraform_remote_state" "auth" {
  backend = "s3"

  workspace = local.integration_environment
  config    = {
    bucket = "terraform-vajeh-auth"
    region = "eu-west-2"
    key    = "dev/app"
  }
}

locals {
  callbacks = ["http://localhost:3000/callback"]
}

// TODO: add project specific test user to pool

resource "aws_cognito_user_pool_client" "client" {
  name = "${local.name_prefix}-frontend"

  user_pool_id        = data.terraform_remote_state.auth.outputs.user_pool_id
  generate_secret     = false
  allowed_oauth_flows = ["code"]
  callback_urls       = local.callbacks
  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"
  ]
  supported_identity_providers = ["COGNITO"]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
}

output "aws_cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}
