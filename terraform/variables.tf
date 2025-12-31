variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "facial-recognition-secure"
}

variable "environment" {
  type = string
}

variable "owner_tag" {
  type    = string
  default = "ike"
}

variable "admin_email" {
  type = string
}

variable "upload_url_ttl_seconds" {
  type    = number
  default = 300
}

variable "face_match_threshold" {
  type    = number
  default = 90
}

variable "image_bucket_name" {
  type        = string
  description = "Existing S3 bucket for facial recognition images"
}

variable "admin_name" {
  type = string
}