# Module: bigquery
# Purpose: BigQuery datasets for Bronze, Silver, and Gold zones

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# BigQuery Datasets
resource "google_bigquery_dataset" "datasets" {
  for_each = var.datasets

  project    = var.project_id
  dataset_id = "${var.name_prefix}_${each.key}"
  location   = var.location

  friendly_name                   = titlecase("${var.environment} - ${each.key} zone")
  description                     = each.value.description
  delete_contents_on_destroy      = each.value.delete_contents_on_destroy
  default_partition_expiration_ms = each.value.default_partition_expiration_ms
  default_table_expiration_ms     = each.value.default_table_expiration_ms

  labels = merge(
    var.labels,
    {
      zone = each.key
    }
  )

  # Access control
  dynamic "access" {
    for_each = each.value.access
    content {
      role           = access.value.role
      user_by_email  = access.value.user_by_email
      group_by_email = access.value.group_by_email
      special_group  = access.value.special_group
    }
  }

  # Customer-Managed Encryption Key
  dynamic "default_encryption_configuration" {
    for_each = var.encryption_key != null ? [1] : []
    content {
      kms_key_name = var.encryption_key
    }
  }
}

# Example data quality monitoring table
resource "google_bigquery_table" "data_quality_metrics" {
  dataset_id = google_bigquery_dataset.datasets["monitoring"].dataset_id
  table_id   = "data_quality_metrics"
  project    = var.project_id

  deletion_protection = var.environment == "prod"

  time_partitioning {
    type  = "DAY"
    field = "check_timestamp"
  }

  schema = jsonencode([
    {
      name = "check_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "dataset_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "table_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "check_type"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "check_result"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "records_checked"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "records_failed"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "error_message"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])

  labels = var.labels
}

# Example pipeline execution tracking table
resource "google_bigquery_table" "pipeline_executions" {
  dataset_id = google_bigquery_dataset.datasets["monitoring"].dataset_id
  table_id   = "pipeline_executions"
  project    = var.project_id

  deletion_protection = var.environment == "prod"

  time_partitioning {
    type  = "DAY"
    field = "execution_timestamp"
  }

  clustering = ["pipeline_name", "status"]

  schema = jsonencode([
    {
      name = "execution_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "execution_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "pipeline_name"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "source_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "status"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "records_processed"
      type = "INTEGER"
      mode = "NULLABLE"
    },
    {
      name = "duration_seconds"
      type = "FLOAT"
      mode = "NULLABLE"
    },
    {
      name = "error_message"
      type = "STRING"
      mode = "NULLABLE"
    }
  ])

  labels = var.labels
}
