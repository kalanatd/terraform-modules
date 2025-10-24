resource "aws_s3_bucket" "config" {
  bucket = "${var.name}-config-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.name}-config"
  }
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "config" {
  bucket  = aws_s3_bucket.config.id
  key     = "config/log-groups.json"
  content = var.log_groups_json
  etag    = md5(var.log_groups_json)
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}