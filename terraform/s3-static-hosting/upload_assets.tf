#data "archive_file" "app_archive" {
#  type        = "zip"
#  source_dir  = var.build_path
#  output_path = "build/app"
#}

#resource "null_resource" "mock-receiver_image_push" {
#  triggers   = {
#    src_hash = data.archive_file.app_archive.output_sha
#  }
#
#  provisioner "local-exec" {
#    command = <<EOF
#           invoke upload-assets
#       EOF
#  }
#}
#
locals {
  mime_types = {
    ".html" = "text/html"
    ".css" = "text/css"
    ".js" = "application/javascript"
    ".ico" = "image/vnd.microsoft.icon"
    ".jpeg" = "image/jpeg"
    ".png" = "image/png"
    ".svg" = "image/svg+xml"
  }
}
resource "aws_s3_object" "upload_assets" {
  bucket = aws_s3_bucket.www_bucket.bucket
  for_each = fileset(var.build_path, "**")
  key = each.value
  source = "${var.build_path}/${each.value}"
  content_type = lookup(local.mime_types, regex("\\.[^.]+$", each.value), null)
  etag = filemd5("${var.build_path}/${each.value}")
}

