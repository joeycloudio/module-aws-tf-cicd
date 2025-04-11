# Instructions: Create resources for S3

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_s3_bucket" "logging_bucket" {
  bucket = "s3-logs-${random_string.suffix.result}"
}

resource "random_string" "codepipeline_artifacts_s3_buckets" {
  for_each = local.safe_codepipeline_pipelines
  length   = 4
  special  = false
  upper    = false
}

resource "aws_s3_bucket" "codepipeline_artifacts_buckets" {
  for_each = local.safe_codepipeline_pipelines
  bucket   = "pipeline-artifacts-${each.value.name}-${random_string.codepipeline_artifacts_s3_buckets[each.key].result}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_encryption" {
  for_each = local.safe_codepipeline_pipelines

  bucket = aws_s3_bucket.codepipeline_artifacts_buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}



  # - Challenge: resolve Checkov issues -
  #checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  #checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"

resource "aws_s3_bucket_public_access_block" "codepipeline_bucket_pabs" {
  for_each = local.safe_codepipeline_pipelines
  bucket   = aws_s3_bucket.codepipeline_artifacts_buckets[each.key].id

  block_public_acls       = var.s3_public_access_block
  block_public_policy     = var.s3_public_access_block
  ignore_public_acls      = var.s3_public_access_block
  restrict_public_buckets = var.s3_public_access_block
}

resource "aws_s3_bucket_versioning" "codepipeline_versioning" {
  for_each = local.safe_codepipeline_pipelines
  bucket   = aws_s3_bucket.codepipeline_artifacts_buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_lifecycle" {
  for_each = local.safe_codepipeline_pipelines
  bucket   = aws_s3_bucket.codepipeline_artifacts_buckets[each.key].id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    filter {
      prefix = ""
    }
  }
}

resource "aws_s3_bucket_logging" "codepipeline_logs" {
  for_each = local.safe_codepipeline_pipelines

  bucket        = aws_s3_bucket.codepipeline_artifacts_buckets[each.key].id
  target_bucket = aws_s3_bucket.logging_bucket.id
  target_prefix = "artifacts-logs/${each.key}/"
}