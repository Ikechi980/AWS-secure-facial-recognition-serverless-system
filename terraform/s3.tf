


resource "aws_s3_bucket" "images" {
  bucket = var.image_bucket_name
}

resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data_key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "images" {
  bucket                  = aws_s3_bucket.images.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_lifecycle_configuration" "verify_images" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire-verify-images"
    status = "Enabled"

    filter {
      prefix = "verify/"
    }

    expiration {
      days = 7
    }
  }
}
