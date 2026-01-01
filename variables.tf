variable "prefix" {
  description = "Prefix for the S3 bucket name. A random suffix will be appended. Either prefix or bucket_name must be provided."
  type        = string
  default     = null

  validation {
    condition     = var.prefix == null || (can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.prefix)) || can(regex("^[a-z0-9]$", var.prefix)))
    error_message = "Prefix must be lowercase letters, numbers, and hyphens. Cannot start or end with a hyphen."
  }

  validation {
    condition     = var.prefix == null || length(var.prefix) <= 40
    error_message = "Prefix must be 40 characters or less to ensure S3 bucket name stays within 63 character limit."
  }
}

variable "bucket_name" {
  description = "Exact S3 bucket name. If provided, prefix is ignored. Must be globally unique across all AWS accounts."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name == null || (can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63)
    error_message = "Bucket name must be 3-63 characters, lowercase letters, numbers, hyphens, and periods. Cannot start or end with hyphen/period."
  }
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default = {
    Environment = "shared"
    Terraform   = "true"
  }
}

variable "force_destroy" {
  description = "When set to true, allows the S3 bucket to be destroyed even if it contains objects. Use with caution in production."
  type        = bool
  default     = false
}

variable "noncurrent_version_retention_days" {
  description = "Number of days to retain noncurrent object versions before deletion. Set to null to disable lifecycle management. Minimum value is 1 when enabled."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_retention_days == null || (var.noncurrent_version_retention_days >= 1 && var.noncurrent_version_retention_days <= 36500)
    error_message = "noncurrent_version_retention_days must be null (disabled) or between 1 and 36500 days."
  }
}
