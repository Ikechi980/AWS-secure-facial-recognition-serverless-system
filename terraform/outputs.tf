output "api_base_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}"
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.images.bucket
}

output "rekognition_collection_id" {
  value = aws_rekognition_collection.faces.collection_id
}
