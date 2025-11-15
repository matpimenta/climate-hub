# Workload Identity Federation Module for GitHub Actions
# Sets up keyless authentication for GitHub Actions to deploy to GCP

# Create Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_actions" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = var.pool_display_name
  description               = var.pool_description
  disabled                  = false
}

# Create OIDC Provider for GitHub Actions
resource "google_iam_workload_identity_pool_provider" "github_actions" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = var.provider_display_name
  description                        = var.provider_description
  disabled                           = false

  # Attribute mapping from GitHub token to Google Cloud attributes
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  # Attribute condition to restrict which repos can authenticate
  # Format: "assertion.repository_owner == 'OWNER'"
  attribute_condition = var.repository_owner != null ? "assertion.repository_owner == '${var.repository_owner}'" : null

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
    # Allowed audiences - default to GitHub's OIDC audience
    allowed_audiences = var.allowed_audiences
  }
}

# Grant service account impersonation to GitHub Actions
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = var.service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = local.workload_identity_member
}

# Additional IAM bindings for specific repositories (optional)
resource "google_service_account_iam_member" "repository_specific" {
  for_each = toset(var.allowed_repositories)

  service_account_id = var.service_account_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${each.value}"
}

# Local variables
locals {
  # Workload identity member for all repos under the owner
  workload_identity_member = var.repository_owner != null ? (
    var.specific_repository != null ?
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${var.repository_owner}/${var.specific_repository}" :
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository_owner/${var.repository_owner}"
  ) : "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/*"
}

# Data source to get project number
data "google_project" "project" {
  project_id = var.project_id
}
