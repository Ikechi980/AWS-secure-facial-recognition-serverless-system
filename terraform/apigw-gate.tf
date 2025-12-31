############################################
# GATE DEVICE API (NO AUTH, PUBLIC)
############################################

resource "aws_api_gateway_rest_api" "gate_api" {
  name = "${local.name_prefix}-gate-api"
}

############################################
# RESOURCES
############################################

resource "aws_api_gateway_resource" "gate_presign" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  parent_id   = aws_api_gateway_rest_api.gate_api.root_resource_id
  path_part   = "presign-upload"
}

resource "aws_api_gateway_resource" "gate_verify" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  parent_id   = aws_api_gateway_rest_api.gate_api.root_resource_id
  path_part   = "verify"
}

############################################
# METHODS (PUBLIC)
############################################

resource "aws_api_gateway_method" "gate_presign_post" {
  rest_api_id   = aws_api_gateway_rest_api.gate_api.id
  resource_id   = aws_api_gateway_resource.gate_presign.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "gate_verify_post" {
  rest_api_id   = aws_api_gateway_rest_api.gate_api.id
  resource_id   = aws_api_gateway_resource.gate_verify.id
  http_method   = "POST"
  authorization = "NONE"
}

############################################
# LAMBDA INTEGRATIONS
############################################

resource "aws_api_gateway_integration" "gate_presign_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gate_api.id
  resource_id             = aws_api_gateway_resource.gate_presign.id
  http_method             = aws_api_gateway_method.gate_presign_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.presign.invoke_arn
}

resource "aws_api_gateway_integration" "gate_verify_integration" {
  rest_api_id             = aws_api_gateway_rest_api.gate_api.id
  resource_id             = aws_api_gateway_resource.gate_verify.id
  http_method             = aws_api_gateway_method.gate_verify_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.verify.invoke_arn
}

############################################
# CORS (OPTIONS)
############################################

resource "aws_api_gateway_method" "gate_presign_options" {
  rest_api_id   = aws_api_gateway_rest_api.gate_api.id
  resource_id   = aws_api_gateway_resource.gate_presign.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gate_presign_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  resource_id = aws_api_gateway_resource.gate_presign.id
  http_method = aws_api_gateway_method.gate_presign_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "gate_presign_options_response" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  resource_id = aws_api_gateway_resource.gate_presign.id
  http_method = aws_api_gateway_method.gate_presign_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "gate_presign_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  resource_id = aws_api_gateway_resource.gate_presign.id
  http_method = aws_api_gateway_method.gate_presign_options.http_method
  status_code = aws_api_gateway_method_response.gate_presign_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Repeat OPTIONS for /verify

resource "aws_api_gateway_method" "gate_verify_options" {
  rest_api_id   = aws_api_gateway_rest_api.gate_api.id
  resource_id   = aws_api_gateway_resource.gate_verify.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "gate_verify_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  resource_id = aws_api_gateway_resource.gate_verify.id
  http_method = aws_api_gateway_method.gate_verify_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "gate_verify_options_response" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  resource_id = aws_api_gateway_resource.gate_verify.id
  http_method = aws_api_gateway_method.gate_verify_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "gate_verify_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id
  resource_id = aws_api_gateway_resource.gate_verify.id
  http_method = aws_api_gateway_method.gate_verify_options.http_method
  status_code = aws_api_gateway_method_response.gate_verify_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

############################################
# LAMBDA PERMISSIONS
############################################

resource "aws_lambda_permission" "allow_gate_presign" {
  statement_id  = "AllowGateInvokePresign"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.presign.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gate_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_gate_verify" {
  statement_id  = "AllowGateInvokeVerify"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.verify.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.gate_api.execution_arn}/*/*"
}

############################################
# DEPLOY
############################################

resource "aws_api_gateway_deployment" "gate_deploy" {
  rest_api_id = aws_api_gateway_rest_api.gate_api.id

  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_integration.gate_presign_integration.id,
      aws_api_gateway_integration.gate_verify_integration.id
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.gate_presign_integration,
    aws_api_gateway_integration.gate_verify_integration
  ]
}

resource "aws_api_gateway_stage" "gate_stage" {
  rest_api_id   = aws_api_gateway_rest_api.gate_api.id
  deployment_id = aws_api_gateway_deployment.gate_deploy.id
  stage_name    = var.environment
}
