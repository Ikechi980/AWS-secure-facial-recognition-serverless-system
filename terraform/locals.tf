locals {
  name_prefix = "${var.project_name}-${var.environment}"

  s3_bucket_name = "${local.name_prefix}-facial-recogn-image-bucket"
  ddb_table_name = "${local.name_prefix}-auth-events"
  cognito_pool   = "${local.name_prefix}-userpool"
  cognito_client = "${local.name_prefix}-appclient"
  rek_collection = "${local.name_prefix}-faces"

  lambda_runtime = "python3.12"
}
