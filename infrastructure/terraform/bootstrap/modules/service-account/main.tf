# Service Account Module for GitHub Actions
# Creates a service account with necessary permissions for Terraform deployments

resource "google_service_account" "github_actions" {
  account_id   = var.account_id
  project      = var.project_id
  display_name = var.display_name
  description  = var.description
}

# Project-level IAM roles
resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset(var.project_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Custom IAM role for more granular permissions (optional)
resource "google_project_iam_custom_role" "terraform_deployer" {
  count = var.create_custom_role ? 1 : 0

  project     = var.project_id
  role_id     = var.custom_role_id
  title       = var.custom_role_title
  description = "Custom role for Terraform deployments via GitHub Actions"
  permissions = var.custom_role_permissions
}

resource "google_project_iam_member" "custom_role_binding" {
  count = var.create_custom_role ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.terraform_deployer[0].id
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Service account keys (not recommended - use Workload Identity instead)
resource "google_service_account_key" "github_actions_key" {
  count = var.create_key ? 1 : 0

  service_account_id = google_service_account.github_actions.name
}
