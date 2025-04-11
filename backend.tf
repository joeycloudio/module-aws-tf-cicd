# Instructions: Dynamically create resources for S3 Remote Backend (Amazon S3 and DynamoDB)

resource "random_string" "tf_remote_state_s3_buckets" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs
  length   = 4
  special  = false
  upper    = false
}

resource "aws_s3_bucket" "tf_remote_state_s3_buckets" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs
  bucket   = "${each.value.prefix}-tf-state-${random_string.tf_remote_state_s3_buckets[each.key].result}"
  force_destroy = true

  # - Challenge: resolve Checkov issues -
  #checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  #checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
  #checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
}

resource "aws_s3_bucket_versioning" "tf_remote_state_s3_buckets" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs
  bucket   = aws_s3_bucket.tf_remote_state_s3_buckets[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_remote_state_lifecycle" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs

  bucket = aws_s3_bucket.tf_remote_state_s3_buckets[each.key].id

  rule {
    id     = "expire-old-state-files"
    status = "Enabled"

    expiration {
      days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {
      prefix = ""
    }
  }
}


resource "aws_s3_bucket_public_access_block" "tf_remote_state_s3_buckets_pabs" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs
  bucket   = aws_s3_bucket.tf_remote_state_s3_buckets[each.key].id

  block_public_acls       = var.s3_public_access_block
  block_public_policy     = var.s3_public_access_block
  ignore_public_acls      = var.s3_public_access_block
  restrict_public_buckets = var.s3_public_access_block
}

# Terraform State Locking
resource "random_string" "tf_remote_state_lock_tables" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs
  length   = 4
  special  = false
  upper    = false
}
resource "aws_dynamodb_table" "tf_remote_state_lock_tables" {
  for_each     = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs
  name         = "${each.value.prefix}-tf-state-lock-${random_string.tf_remote_state_lock_tables[each.key].result}"
  billing_mode = each.value.ddb_billing_mode
  hash_key     = each.value.ddb_hash_key

  attribute {
    name = each.value.ddb_hash_key
    type = "S"
  }

    point_in_time_recovery {
    enabled = true
  }

    server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_encryption.arn
  }



  # - Challenge: resolve Checkov issues -
  #checkov:skip=CKV2_AWS_16: "Ensure that Auto Scaling is enabled on your DynamoDB tables"
}

resource "aws_s3_bucket_logging" "tf_backend_logs" {
  for_each = var.tf_remote_state_resource_configs == null ? {} : var.tf_remote_state_resource_configs

  bucket        = aws_s3_bucket.tf_remote_state_s3_buckets[each.key].id
  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = "remote-state-logs/${each.key}/"
}

resource "aws_kms_key" "dynamodb_encryption" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
