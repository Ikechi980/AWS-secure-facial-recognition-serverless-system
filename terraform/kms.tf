resource "aws_kms_key" "data_key" {
  description             = "KMS key for ${local.name_prefix}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "data_key_alias" {
  name          = "alias/${local.name_prefix}-data"
  target_key_id = aws_kms_key.data_key.key_id
}
