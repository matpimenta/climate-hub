# Module: storage
# Purpose: GCS buckets for Bronze, Silver, Gold zones and other storage needs

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  # Standard bucket configurations
  buckets_config = {
    bronze = {
      name_suffix     = "bronze"
      location        = var.region
      storage_class   = var.bronze_zone.storage_class
      versioning      = var.bronze_zone.enable_versioning
      lifecycle_rules = var.bronze_zone.retention_days > 0 ? concat(
        var.bronze_zone.nearline_after_days != null ? [{
          action = {
            type          = "SetStorageClass"
            storage_class = "NEARLINE"
          }
          condition = {
            age                   = var.bronze_zone.nearline_after_days
            matches_storage_class = ["STANDARD"]
          }
        }] : [],
        var.bronze_zone.coldline_after_days != null ? [{
          action = {
            type          = "SetStorageClass"
            storage_class = "COLDLINE"
          }
          condition = {
            age                   = var.bronze_zone.coldline_after_days
            matches_storage_class = ["STANDARD", "NEARLINE"]
          }
        }] : [],
        [{
          action = {
            type = "Delete"
          }
          condition = {
            age = var.bronze_zone.retention_days
          }
        }]
      ) : []
    }

    silver = {
      name_suffix     = "silver"
      location        = var.region
      storage_class   = var.silver_zone.storage_class
      versioning      = var.silver_zone.enable_versioning
      lifecycle_rules = var.silver_zone.retention_days > 0 ? concat(
        var.silver_zone.nearline_after_days != null ? [{
          action = {
            type          = "SetStorageClass"
            storage_class = "NEARLINE"
          }
          condition = {
            age                   = var.silver_zone.nearline_after_days
            matches_storage_class = ["STANDARD"]
          }
        }] : [],
        var.silver_zone.coldline_after_days != null ? [{
          action = {
            type          = "SetStorageClass"
            storage_class = "COLDLINE"
          }
          condition = {
            age                   = var.silver_zone.coldline_after_days
            matches_storage_class = ["STANDARD", "NEARLINE"]
          }
        }] : [],
        [{
          action = {
            type = "Delete"
          }
          condition = {
            age = var.silver_zone.retention_days
          }
        }]
      ) : []
    }

    landing = {
      name_suffix     = "landing"
      location        = var.region
      storage_class   = var.landing_zone.storage_class
      versioning      = var.landing_zone.enable_versioning
      lifecycle_rules = var.landing_zone.retention_days > 0 ? [{
        action = {
          type = "Delete"
        }
        condition = {
          age = var.landing_zone.retention_days
        }
      }] : []
    }

    dataflow_staging = {
      name_suffix     = "dataflow-staging"
      location        = var.region
      storage_class   = var.dataflow_staging.storage_class
      versioning      = var.dataflow_staging.enable_versioning
      lifecycle_rules = var.dataflow_staging.retention_days > 0 ? [{
        action = {
          type = "Delete"
        }
        condition = {
          age = var.dataflow_staging.retention_days
        }
      }] : []
    }
  }
}

# GCS Buckets
resource "google_storage_bucket" "buckets" {
  for_each = local.buckets_config

  name          = "${each.value.name_suffix}-${var.project_id}-${var.region}"
  project       = var.project_id
  location      = each.value.location
  storage_class = each.value.storage_class
  force_destroy = var.environment != "prod" # Allow destruction in non-prod

  # Uniform bucket-level access (recommended)
  uniform_bucket_level_access = true

  # Versioning
  versioning {
    enabled = each.value.versioning
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = try(lifecycle_rule.value.action.storage_class, null)
      }
      condition {
        age                   = try(lifecycle_rule.value.condition.age, null)
        matches_storage_class = try(lifecycle_rule.value.condition.matches_storage_class, null)
      }
    }
  }

  # Encryption
  dynamic "encryption" {
    for_each = var.encryption_key != null ? [1] : []
    content {
      default_kms_key_name = var.encryption_key
    }
  }

  # Labels
  labels = merge(
    var.labels,
    {
      zone        = each.key
      data_tier   = contains(["bronze", "silver"], each.key) ? "data_lake" : "operational"
    }
  )
}

# Bronze zone bucket notification to Pub/Sub (for file ingestion)
resource "google_storage_notification" "bronze_notification" {
  count = var.enable_pubsub_notifications ? 1 : 0

  bucket         = google_storage_bucket.buckets["bronze"].name
  payload_format = "JSON_API_V1"
  topic          = var.pubsub_topic_id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_storage_bucket.buckets]
}

# Landing zone bucket notification
resource "google_storage_notification" "landing_notification" {
  count = var.enable_pubsub_notifications ? 1 : 0

  bucket         = google_storage_bucket.buckets["landing"].name
  payload_format = "JSON_API_V1"
  topic          = var.pubsub_topic_id
  event_types    = ["OBJECT_FINALIZE"]

  depends_on = [google_storage_bucket.buckets]
}

# IAM binding for service accounts
resource "google_storage_bucket_iam_member" "dataflow_admin" {
  for_each = toset(["bronze", "silver", "dataflow_staging"])

  bucket = google_storage_bucket.buckets[each.key].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.dataflow_service_account}"
}

resource "google_storage_bucket_iam_member" "landing_writer" {
  bucket = google_storage_bucket.buckets["landing"].name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.cloud_functions_service_account}"
}
