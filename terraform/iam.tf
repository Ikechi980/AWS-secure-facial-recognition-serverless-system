data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.images.arn}/enroll/*",
      "${aws_s3_bucket.images.arn}/verify/*",
      "arn:aws:s3:::facial-recogn-image-bucket/gate/*"
    ]
  }


  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem"
    ]
    resources = [
      aws_dynamodb_table.auth_events.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "rekognition:IndexFaces",
      "rekognition:SearchFacesByImage",
      "rekognition:DetectFaces"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.data_key.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::facial-recogn-image-bucket/*",
      "arn:aws:s3:::facial-recogn-image-bucket/enroll/*",
      "arn:aws:s3:::facial-recogn-image-bucket/verify/*"

    ]
  }

}

resource "aws_iam_role_policy" "lambda_inline" {
  name   = "${local.name_prefix}-lambda-inline"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "gate_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.gate_pool.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}

resource "aws_iam_role" "gate_role" {
  name               = "${local.name_prefix}-gate-role"
  assume_role_policy = data.aws_iam_policy_document.gate_assume_role.json
}

data "aws_iam_policy_document" "gate_policy" {
  statement {
    effect = "Allow"
    actions = [
      "execute-api:Invoke"
    ]
    resources = [
      "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/verify"
    ]
  }
}

resource "aws_iam_role_policy" "gate_inline" {
  role   = aws_iam_role.gate_role.id
  policy = data.aws_iam_policy_document.gate_policy.json
}

