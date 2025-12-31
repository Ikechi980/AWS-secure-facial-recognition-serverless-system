resource "aws_cognito_user_pool" "pool" {
  name = local.cognito_pool

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }
}

resource "aws_cognito_user_pool_client" "client" {
  name         = local.cognito_client
  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = ["http://localhost:3000/callback"]
  logout_urls   = ["http://localhost:3000/logout"]

  supported_identity_providers = ["COGNITO"]
}

resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = var.admin_name

  attributes = {
    email          = var.admin_email
    email_verified = "true"
  }

  force_alias_creation = false
  message_action       = "SUPPRESS"
}


resource "aws_cognito_identity_pool" "gate_pool" {
  identity_pool_name               = "${local.name_prefix}-gate-pool"
  allow_unauthenticated_identities = true
}

resource "aws_cognito_identity_pool_roles_attachment" "gate_attach" {
  identity_pool_id = aws_cognito_identity_pool.gate_pool.id

  roles = {
    unauthenticated = aws_iam_role.gate_role.arn
  }
}
