locals {
  bucket_name = var.domain
}

# S3 bucket for redirecting non-www to www.
resource "aws_s3_bucket" "root_bucket" {
  bucket = local.bucket_name
  tags   = { domain = var.domain }
}
resource "aws_s3_bucket_acl" "root_bucket_acl" {
  bucket = aws_s3_bucket.root_bucket.id
  acl    = "public-read"
}
resource "aws_s3_bucket_policy" "root_bucket_policy" {
  bucket = aws_s3_bucket.root_bucket.id
  policy = templatefile("${path.module}/templates/s3-policy.json", { bucket = local.bucket_name })
}
resource "aws_s3_bucket_website_configuration" "root_bucket_website_config" {
  bucket = aws_s3_bucket.root_bucket.id
  redirect_all_requests_to {
    host_name = "https://www.${var.domain}"
  }
}

resource "aws_s3_bucket" "www_bucket" {
  bucket = "www.${local.bucket_name}"
  tags   = { domain = var.domain }
}
resource "aws_s3_bucket_acl" "www_bucket_acl" {
  bucket = aws_s3_bucket.www_bucket.id
  acl    = "public-read"
}
resource "aws_s3_bucket_cors_configuration" "www_bucket_cors" {
  bucket = aws_s3_bucket.www_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://www.${var.domain}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
resource "aws_s3_bucket_policy" "www_bucket_policy" {
  bucket = aws_s3_bucket.www_bucket.id
  policy = templatefile("${path.module}/templates/s3-policy.json", { bucket = "www.${local.bucket_name}" })
}
resource "aws_s3_bucket_website_configuration" "www_bucket_website_config" {
  bucket = aws_s3_bucket.www_bucket.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "404.html"
  }
}
