# Bootstrap Environment Outputs

# ============================================================================
# STATE BUCKET OUTPUTS
# ============================================================================

output "state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = module.state_bucket.bucket_name
}

output "state_bucket_url" {
  description = "URL of the Terraform state bucket"
  value       = module.state_bucket.bucket_url
}

# ============================================================================
# SERVICE ACCOUNT OUTPUTS
# ============================================================================

output "service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = module.service_account.service_account_email
}

output "service_account_id" {
  description = "ID of the GitHub Actions service account"
  value       = module.service_account.service_account_id
}

# ============================================================================
# WORKLOAD IDENTITY OUTPUTS
# ============================================================================

output "workload_identity_provider" {
  description = "Full resource name of the Workload Identity Provider (use this in GitHub Actions)"
  value       = module.workload_identity.workload_identity_provider_name
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = module.workload_identity.workload_identity_pool_id
}

output "project_number" {
  description = "GCP project number"
  value       = module.workload_identity.project_number
}

# ============================================================================
# GITHUB ACTIONS CONFIGURATION
# ============================================================================

output "github_actions_secrets" {
  description = "Values to configure as GitHub Actions secrets"
  value = {
    GCP_WORKLOAD_IDENTITY_PROVIDER = module.workload_identity.workload_identity_provider_name
    GCP_SERVICE_ACCOUNT            = module.service_account.service_account_email
  }
  sensitive = false
}

output "github_actions_setup_summary" {
  description = "Summary of setup for GitHub Actions"
  value = <<-EOT

    ================================================================================
    GitHub Actions Setup Complete!
    ================================================================================

    Add these secrets to your GitHub repository:
    (Go to: Settings → Secrets and variables → Actions → New repository secret)

    1. GCP_WORKLOAD_IDENTITY_PROVIDER
       Value: ${module.workload_identity.workload_identity_provider_name}

    2. GCP_SERVICE_ACCOUNT
       Value: ${module.service_account.service_account_email}

    ================================================================================
    Terraform Backend Configuration:
    ================================================================================

    Use this backend configuration in your Terraform environments:

    terraform {
      backend "gcs" {
        bucket = "${module.state_bucket.bucket_name}"
        prefix = "environments/<ENV_NAME>"
      }
    }

    Or initialize with:

    terraform init \
      -backend-config="bucket=${module.state_bucket.bucket_name}" \
      -backend-config="prefix=environments/dev"

    ================================================================================
    Project Information:
    ================================================================================

    Project ID:      ${var.project_id}
    Project Number:  ${module.workload_identity.project_number}
    Region:          ${var.region}

    State Bucket:    ${module.state_bucket.bucket_name}
    Service Account: ${module.service_account.service_account_email}

    GitHub Owner:    ${var.github_repository_owner}
    GitHub Repo:     ${var.github_repository_name != null ? "${var.github_repository_owner}/${var.github_repository_name}" : "All repos under ${var.github_repository_owner}"}

    ================================================================================
  EOT
}
