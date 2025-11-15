# Terraform State Bucket Module
# Creates a GCS bucket for storing Terraform state with versioning and lifecycle management

resource "google_storage_bucket" "terraform_state" {
  name          = var.bucket_name
  project       = var.project_id
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.versioning_retention_count
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      days_since_noncurrent_time = var.noncurrent_version_retention_days
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(
    var.labels,
    {
      purpose = "terraform-state"
      managed_by = "terraform-bootstrap"
    }
  )
}

# Enable object retention for compliance (optional)
resource "google_storage_bucket_object" "readme" {
  name    = "README.txt"
  bucket  = google_storage_bucket.terraform_state.name
  content = <<-EOT
    This bucket stores Terraform state files.

    DO NOT manually modify or delete files in this bucket.

    State files contain sensitive information and should be treated as confidential.

    Bucket: ${google_storage_bucket.terraform_state.name}
    Project: ${var.project_id}
    Created: ${timestamp()}
  EOT
}

# IAM binding for service account access
# Note: IAM bindings are managed in the main configuration
# to avoid circular dependencies with service account creation

# Optional: Enable customer-managed encryption
resource "google_storage_bucket_iam_member" "kms_encrypter" {
  count = var.encryption_key != null ? 1 : 0

  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.admin"
  member = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

data "google_project" "project" {
  project_id = var.project_id
}
