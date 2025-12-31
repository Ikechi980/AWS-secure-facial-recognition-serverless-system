resource "aws_api_gateway_rest_api" "api" {
  name = "${local.name_prefix}-api"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${local.name_prefix}-cognito-auth"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.Authorization"
}

resource "aws_api_gateway_resource" "presign" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "presign-upload"
}

resource "aws_api_gateway_resource" "enroll" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "enroll"
}

resource "aws_api_gateway_resource" "verify" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "verify"
}

# Methods
resource "aws_api_gateway_method" "presign_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.presign.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "enroll_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.enroll.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_method" "verify_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.verify.id
  http_method   = "POST"
  authorization = "AWS_IAM"
}


# Lambda integrations
resource "aws_api_gateway_integration" "presign_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.presign.id
  http_method             = aws_api_gateway_method.presign_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.presign.invoke_arn
}

resource "aws_api_gateway_integration" "enroll_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.enroll.id
  http_method             = aws_api_gateway_method.enroll_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.enroll.invoke_arn
}

resource "aws_api_gateway_integration" "verify_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.verify.id
  http_method             = aws_api_gateway_method.verify_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.verify.invoke_arn
}

# Permissions so API Gateway can invoke Lambdas
resource "aws_lambda_permission" "allow_apigw_presign" {
  statement_id  = "AllowAPIGatewayInvokePresign"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_enroll" {
  statement_id  = "AllowAPIGatewayInvokeEnroll"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.enroll.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_verify" {
  statement_id  = "AllowAPIGatewayInvokeVerify"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# Deploy
resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_integration.presign_integration.id,
      aws_api_gateway_integration.enroll_integration.id,
      aws_api_gateway_integration.verify_integration.id
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.presign_integration,
    aws_api_gateway_integration.enroll_integration,
    aws_api_gateway_integration.verify_integration
  ]
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = var.environment
}
