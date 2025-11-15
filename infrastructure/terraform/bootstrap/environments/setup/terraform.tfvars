# Bootstrap Configuration Example
# Copy this file to terraform.tfvars and update with your values

# ============================================================================
# PROJECT CONFIGURATION (REQUIRED)
# ============================================================================

# Your GCP project ID
project_id = "climate-hub-478222"

# Default GCP region
region = "europe-west2"

# ============================================================================
# GITHUB CONFIGURATION (REQUIRED)
# ============================================================================

# GitHub repository owner (username or organization)
github_repository_owner = "matpimenta"

# GitHub repository name (without owner)
# Leave as null to allow all repos under the owner
# Set to specific repo name to restrict (e.g., "np-spawner")
github_repository_name = "climate-hub"

# ============================================================================
# STATE BUCKET CONFIGURATION (OPTIONAL)
# ============================================================================

# Location for Terraform state bucket
# Options: "US", "EU", or specific region like "us-central1"
state_bucket_location = "EU"

# Allow destroying state bucket (DANGEROUS - only for testing)
allow_state_bucket_destroy = false

# ============================================================================
# SERVICE ACCOUNT CONFIGURATION (OPTIONAL)
# ============================================================================

# Service account ID (will create: ID@PROJECT_ID.iam.gserviceaccount.com)
service_account_id = "github-actions-terraform"

# Display name for the service account
service_account_display_name = "GitHub Actions Terraform Deployer"

# IAM roles to grant to the service account
# Adjust based on your security requirements
service_account_roles = [
  "roles/editor",                          # Manage most GCP resources
  "roles/iam.securityAdmin",               # Manage IAM policies
  "roles/resourcemanager.projectIamAdmin", # Manage project IAM
  "roles/compute.networkAdmin",            # Manage VPC and networking resources
  "roles/servicenetworking.networksAdmin", # Manage service networking connections (VPC peering)
  "roles/bigquery.admin",                  # Manage BigQuery datasets and tables
]

# ============================================================================
# WORKLOAD IDENTITY CONFIGURATION (OPTIONAL)
# ============================================================================

# Workload Identity Pool ID
workload_identity_pool_id = "github-actions-pool"

# Workload Identity Provider ID
workload_identity_provider_id = "github-actions-provider"
