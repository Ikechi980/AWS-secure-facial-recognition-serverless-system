data "archive_file" "presign_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../build/presign.zip"
}

data "archive_file" "enroll_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../build/enroll.zip"
}

data "archive_file" "verify_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/../build/verify.zip"
}

resource "aws_lambda_function" "presign" {
  function_name = "${local.name_prefix}-presign-upload"
  role          = aws_iam_role.lambda_role.arn
  runtime       = local.lambda_runtime
  handler       = "presign_upload.handler"
  filename      = data.archive_file.presign_zip.output_path
  timeout       = 10
  memory_size   = 256

  environment {
    variables = {
      BUCKET_NAME            = aws_s3_bucket.images.bucket
      KMS_KEY_ARN            = aws_kms_key.data_key.arn
      UPLOAD_URL_TTL_SECONDS = tostring(var.upload_url_ttl_seconds)
    }
  }
}

resource "aws_lambda_function" "enroll" {
  function_name = "${local.name_prefix}-enroll"
  role          = aws_iam_role.lambda_role.arn
  runtime       = local.lambda_runtime
  handler       = "enroll.handler"
  filename      = data.archive_file.enroll_zip.output_path
  timeout       = 20
  memory_size   = 512

  environment {
    variables = {
      BUCKET_NAME      = aws_s3_bucket.images.bucket
      DDB_TABLE_NAME   = aws_dynamodb_table.auth_events.name
      COLLECTION_ID    = aws_rekognition_collection.faces.collection_id
      FACE_THRESHOLD   = tostring(var.face_match_threshold)
      ENVIRONMENT      = var.environment
      PROJECT_NAME     = var.project_name
    }
  }
}

resource "aws_lambda_function" "verify" {
  function_name = "${local.name_prefix}-verify"
  role          = aws_iam_role.lambda_role.arn
  runtime       = local.lambda_runtime
  handler       = "verify.handler"
  filename      = data.archive_file.verify_zip.output_path
  timeout       = 20
  memory_size   = 512

  environment {
    variables = {
      BUCKET_NAME      = aws_s3_bucket.images.bucket
      DDB_TABLE_NAME   = aws_dynamodb_table.auth_events.name
      COLLECTION_ID    = aws_rekognition_collection.faces.collection_id
      FACE_THRESHOLD   = tostring(var.face_match_threshold)
      ENVIRONMENT      = var.environment
      PROJECT_NAME     = var.project_name
    }
  }
}
