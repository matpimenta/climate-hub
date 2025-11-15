# Module: security
# Purpose: IAM, Service Accounts, Secret Manager, and KMS encryption

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Service Accounts for each component
resource "google_service_account" "service_accounts" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = "${var.name_prefix}-${each.key}"
  display_name = each.value.display_name
  description  = each.value.description
}

# IAM role bindings for service accounts
resource "google_project_iam_member" "sa_roles" {
  for_each = {
    for pair in flatten([
      for sa_key, sa in var.service_accounts : [
        for role in sa.roles : {
          sa_key = sa_key
          role   = role
        }
      ]
    ]) : "${pair.sa_key}-${pair.role}" => pair
  }

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.sa_key].email}"
}

# KMS Key Ring (Customer-Managed Encryption Keys)
resource "google_kms_key_ring" "keyring" {
  count = var.enable_cmek ? 1 : 0

  name     = var.kms_key_ring_name
  project  = var.project_id
  location = var.region
}

# KMS Crypto Keys
resource "google_kms_crypto_key" "keys" {
  for_each = var.kms_crypto_keys

  name            = "${var.name_prefix}-${each.key}"
  key_ring        = google_kms_key_ring.keyring[0].id
  rotation_period = each.value.rotation_period
  purpose         = each.value.purpose

  lifecycle {
    prevent_destroy = true
  }
}

# Grant service accounts permission to use KMS keys
resource "google_kms_crypto_key_iam_member" "crypto_key_encrypter_decrypter" {
  for_each = var.enable_cmek ? toset([
    "dataflow",
    "cloud_functions",
    "cloud_run",
    "composer"
  ]) : []

  crypto_key_id = google_kms_crypto_key.keys["storage"].id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.service_accounts[each.key].email}"
}

# Secret Manager for API keys and credentials
# Placeholder - actual secrets should be created and populated manually or via CI/CD
resource "google_secret_manager_secret" "api_keys_placeholder" {
  count = 0 # Disabled by default - create specific secrets as needed

  project   = var.project_id
  secret_id = "${var.name_prefix}-api-key-placeholder"

  replication {
    automatic = true
  }

  labels = var.labels
}
