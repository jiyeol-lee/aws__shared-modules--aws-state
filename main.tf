terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Determine if using exact name or prefix
  use_exact_name = var.bucket_name != null
}

check "bucket_naming" {
  assert {
    condition     = var.prefix != null || var.bucket_name != null
    error_message = "Either prefix or bucket_name must be provided."
  }
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "state" {
  # Use exact bucket_name if provided, otherwise use bucket_prefix
  bucket        = local.use_exact_name ? var.bucket_name : null
  bucket_prefix = local.use_exact_name ? null : "${var.prefix}-terraform-state-"

  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Name      = local.use_exact_name ? var.bucket_name : "${var.prefix}-terraform-state"
    ManagedBy = "Terraform"
  })
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Policy for Terraform State Access
data "aws_iam_policy_document" "terraform_state" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "terraform_state" {
  name_prefix = local.use_exact_name ? "${var.bucket_name}-" : "${var.prefix}-terraform-state-"
  description = "Policy for Terraform state access to S3 bucket ${aws_s3_bucket.state.id}"
  policy      = data.aws_iam_policy_document.terraform_state.json

  tags = merge(var.tags, {
    Name      = local.use_exact_name ? "${var.bucket_name}-policy" : "${var.prefix}-terraform-state-policy"
    ManagedBy = "Terraform"
  })
}

# Lifecycle configuration for noncurrent version management
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  count  = var.noncurrent_version_retention_days != null ? 1 : 0
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_retention_days
    }

    dynamic "noncurrent_version_transition" {
      for_each = var.noncurrent_version_retention_days > 30 ? [1] : []
      content {
        noncurrent_days = 30
        storage_class   = "STANDARD_IA"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}
