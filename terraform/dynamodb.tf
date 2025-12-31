resource "aws_dynamodb_table" "auth_events" {
  name         = local.ddb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.data_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }
}
