# Bootstrap Configuration for GitHub Actions CI/CD
# This Terraform configuration sets up:
# 1. GCS bucket for Terraform state
# 2. Service account for GitHub Actions
# 3. Workload Identity Federation for keyless authentication

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Note: This bootstrap configuration uses local state
  # After initial setup, you can migrate to remote state if desired
  backend "gcs" {
    prefix = "environments/setup"
    bucket = "climate-hub-478222-terraform-state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Local variables
locals {
  state_bucket_name = "${var.project_id}-terraform-state"

  common_labels = {
    environment = "bootstrap"
    managed_by  = "terraform"
    purpose     = "cicd-setup"
  }
}

# ============================================================================
# ENABLE REQUIRED APIS
# ============================================================================

resource "google_project_service" "required_apis" {
  for_each = toset([
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "sts.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# ============================================================================
# TERRAFORM STATE BUCKET
# ============================================================================

module "state_bucket" {
  source = "../../modules/state-bucket"

  project_id    = var.project_id
  bucket_name   = local.state_bucket_name
  location      = var.state_bucket_location
  force_destroy = var.allow_state_bucket_destroy

  labels = local.common_labels

  depends_on = [google_project_service.required_apis]
}

# ============================================================================
# SERVICE ACCOUNT FOR GITHUB ACTIONS
# ============================================================================

module "service_account" {
  source = "../../modules/service-account"

  project_id   = var.project_id
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
  description  = "Service account for deploying infrastructure via GitHub Actions"

  project_roles = var.service_account_roles

  # Do not create service account keys - use Workload Identity instead
  create_key = false

  depends_on = [google_project_service.required_apis]
}

# ============================================================================
# WORKLOAD IDENTITY FEDERATION
# ============================================================================

module "workload_identity" {
  source = "../../modules/workload-identity"

  project_id         = var.project_id
  pool_id            = var.workload_identity_pool_id
  pool_display_name  = "GitHub Actions Pool"
  pool_description   = "Workload Identity Pool for GitHub Actions CI/CD"

  provider_id           = var.workload_identity_provider_id
  provider_display_name = "GitHub Actions OIDC Provider"
  provider_description  = "OIDC provider for GitHub Actions authentication"

  service_account_name = module.service_account.service_account_name
  repository_owner     = var.github_repository_owner
  specific_repository  = var.github_repository_name

  depends_on = [
    google_project_service.required_apis,
    module.service_account
  ]
}

# ============================================================================
# GRANT STATE BUCKET ACCESS TO SERVICE ACCOUNT
# ============================================================================

resource "google_storage_bucket_iam_member" "state_bucket_admin" {
  bucket = module.state_bucket.bucket_name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.service_account.service_account_email}"

  depends_on = [module.state_bucket, module.service_account]
}
