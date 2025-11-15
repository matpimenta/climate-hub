# Bootstrap Environment Variables

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default GCP region"
  type        = string
  default     = "us-central1"
}

# ============================================================================
# STATE BUCKET CONFIGURATION
# ============================================================================

variable "state_bucket_location" {
  description = "Location for the Terraform state bucket (US, EU, or specific region)"
  type        = string
  default     = "US"
}

variable "allow_state_bucket_destroy" {
  description = "Allow destroying the state bucket even if it contains objects (DANGEROUS - use only for testing)"
  type        = bool
  default     = false
}

# ============================================================================
# SERVICE ACCOUNT CONFIGURATION
# ============================================================================

variable "service_account_id" {
  description = "ID for the GitHub Actions service account"
  type        = string
  default     = "github-actions-terraform"
}

variable "service_account_display_name" {
  description = "Display name for the service account"
  type        = string
  default     = "GitHub Actions Terraform Deployer"
}

variable "service_account_roles" {
  description = "IAM roles to grant to the service account"
  type        = list(string)
  default = [
    "roles/editor",
    "roles/iam.securityAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/compute.networkAdmin",
    "roles/servicenetworking.networksAdmin",
    "roles/bigquery.admin",
  ]
}

# ============================================================================
# WORKLOAD IDENTITY CONFIGURATION
# ============================================================================

variable "workload_identity_pool_id" {
  description = "ID for the Workload Identity Pool"
  type        = string
  default     = "github-actions-pool"
}

variable "workload_identity_provider_id" {
  description = "ID for the Workload Identity Provider"
  type        = string
  default     = "github-actions-provider"
}

# ============================================================================
# GITHUB CONFIGURATION
# ============================================================================

variable "github_repository_owner" {
  description = "GitHub repository owner (username or organization)"
  type        = string
}

variable "github_repository_name" {
  description = "GitHub repository name (without owner, e.g., 'my-repo' not 'owner/my-repo'). Leave empty to allow all repos under the owner."
  type        = string
  default     = null
}
