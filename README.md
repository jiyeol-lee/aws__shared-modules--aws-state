# AWS State Module

Terraform module for creating an S3 bucket for Terraform state management with native S3 locking support and lifecycle policies for noncurrent version management.

## Overview

This module creates the foundation for Terraform state management:

- **S3 Bucket**: Stores Terraform state files with versioning and encryption
- **Lifecycle Policy**: Automatically transitions and expires noncurrent versions to manage storage costs
- **IAM Policy**: Grants necessary permissions for Terraform operations

Native S3 locking (`use_lockfile = true`) requires Terraform 1.10 or later, eliminating the need for a DynamoDB table for state locking.

## Usage

### Basic Usage (Prefix-based naming)

```hcl
module "terraform_state" {
  source = "git@github.com:your-org/aws__shared-modules--aws-state.git"

  prefix = "my-project"
}
```

### Exact Bucket Name

```hcl
module "terraform_state" {
  source = "git@github.com:your-org/aws__shared-modules--aws-state.git"

  # Use exact bucket name instead of prefix
  # Note: Must be globally unique across all AWS accounts
  bucket_name = "my-company-terraform-state-prod"
}
```

### Complete Usage

```hcl
module "terraform_state" {
  source = "git@github.com:your-org/aws__shared-modules--aws-state.git"

  prefix = "my-project"

  # Lifecycle settings for noncurrent versions
  noncurrent_version_retention_days = 90

  tags = {
    Project     = "my-project"
    Environment = "production"
    Owner       = "team"
  }

  force_destroy = false
}
```

### Backend Configuration

After creating the state bucket, configure your S3 backend with native locking:

```hcl
terraform {
  backend "s3" {
    bucket       = "my-project-terraform-state-xxxxx"
    key          = "path/to/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true  # Requires Terraform 1.10+
  }
}
```

## Inputs

| Name                              | Description                                                                                                                                          | Type          | Default                                          | Required |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------------------------------------------------ | :------: |
| prefix                            | Prefix for the S3 bucket name. A random suffix will be appended. Either prefix or bucket_name must be provided. Max 40 characters.                   | `string`      | `null`                                           |    no    |
| bucket_name                       | Exact S3 bucket name. If provided, prefix is ignored. Must be globally unique across all AWS accounts. 3-63 characters.                              | `string`      | `null`                                           |    no    |
| noncurrent_version_retention_days | Number of days to retain noncurrent object versions before deletion. Set to `null` to disable lifecycle management. Minimum value is 1 when enabled. | `number`      | `90`                                             |    no    |
| tags                              | Tags to apply to all resources created by this module.                                                                                               | `map(string)` | `{"Environment": "shared", "Terraform": "true"}` |    no    |
| force_destroy                     | When true, allows S3 bucket destruction even with objects. Use with caution.                                                                         | `bool`        | `false`                                          |    no    |

> **Note**: Either `prefix` or `bucket_name` must be provided. When using `prefix`, a random suffix is appended (e.g., `my-project-terraform-state-abc123`). When using `bucket_name`, you must ensure the name is globally unique across all AWS accounts.
>
> The prefix is limited to 40 characters to ensure the generated S3 bucket name (which includes `-terraform-state-` and a random suffix) stays within the 63 character limit for S3 bucket names.

### Lifecycle Management

The `noncurrent_version_retention_days` variable controls the lifecycle policy for noncurrent object versions:

- **Disable lifecycle management**: Set `noncurrent_version_retention_days = null` to disable lifecycle management entirely. No lifecycle rules will be created.
- **Minimum value**: When enabled, the minimum value is 1 day.
- **STANDARD_IA transition**: Noncurrent versions only transition to STANDARD_IA storage class when `noncurrent_version_retention_days > 30`. For shorter retention periods, versions are deleted without transitioning.

> **Breaking Change**: Previous versions used `0` to disable expiration. This is no longer valid. Use `null` instead to disable lifecycle management.

## Outputs

| Name              | Description                                                                                                          |
| ----------------- | -------------------------------------------------------------------------------------------------------------------- |
| bucket_name       | Name of the S3 bucket for Terraform state storage                                                                    |
| bucket_arn        | ARN of the S3 bucket                                                                                                 |
| bucket_region     | AWS region where the S3 bucket is located                                                                            |
| policy_arn        | ARN of the IAM policy for Terraform state access                                                                     |
| policy_id         | ID of the IAM policy                                                                                                 |
| lifecycle_rule_id | ID of the S3 lifecycle rule for noncurrent version expiration. Returns `null` when lifecycle management is disabled. |

## Features

- **Versioning**: Enabled to maintain state history and enable recovery
- **Lifecycle Policy**: When enabled, noncurrent versions transition to STANDARD_IA after 30 days (if retention > 30 days) and expire after the configured retention period (default 90 days). Set to `null` to disable lifecycle management entirely.
- **Encryption**: Server-side encryption with AES256
- **Public Access Blocked**: All public access settings are blocked
- **IAM Policy**: Pre-configured policy for Terraform state operations

## Security Considerations

1. **S3 Bucket Security**:
   - Public access is blocked by default
   - Server-side encryption enabled (AES256)
   - Versioning enabled for recovery

2. **IAM Security**:
   - Policy follows least privilege principle
   - Only necessary S3 actions allowed (GetObject, PutObject, DeleteObject, ListBucket)

3. **Best Practices**:
   - Use unique prefixes per environment
   - Rotate AWS credentials regularly
   - Use IAM roles instead of access keys when possible
