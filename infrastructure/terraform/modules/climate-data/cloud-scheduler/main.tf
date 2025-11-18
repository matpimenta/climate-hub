# Cloud Scheduler jobs for climate data ingestion
# This module creates scheduled jobs to trigger data ingestion Cloud Functions

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "global_warming_function_url" {
  description = "URL of the Global Warming API Cloud Function"
  type        = string
}

variable "nasa_gistemp_function_url" {
  description = "URL of the NASA GISTEMP Cloud Function"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Cloud Scheduler"
  type        = string
}

variable "global_warming_schedule" {
  description = "Cron schedule for Global Warming API job"
  type        = string
  default     = "0 2 5 * *" # Monthly on the 5th at 2 AM UTC
}

variable "nasa_gistemp_schedule" {
  description = "Cron schedule for NASA GISTEMP job"
  type        = string
  default     = "0 3 15 * *" # Monthly on the 15th at 3 AM UTC
}

variable "time_zone" {
  description = "Time zone for the schedule"
  type        = string
  default     = "UTC"
}

# Cloud Scheduler job for Global Warming API ingestion
resource "google_cloud_scheduler_job" "global_warming_api_monthly" {
  name        = "global-warming-api-monthly-${var.environment}"
  description = "Monthly ingestion of Global Warming API climate data"
  schedule    = var.global_warming_schedule
  time_zone   = var.time_zone
  project     = var.project_id
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = var.global_warming_function_url

    oidc_token {
      service_account_email = var.service_account_email
    }
  }

  retry_config {
    retry_count          = 3
    max_retry_duration   = "3600s"
    min_backoff_duration = "60s"
    max_backoff_duration = "600s"
  }
}

# Cloud Scheduler job for NASA GISTEMP ingestion
resource "google_cloud_scheduler_job" "nasa_gistemp_monthly" {
  name        = "nasa-gistemp-monthly-${var.environment}"
  description = "Monthly ingestion of NASA GISTEMP v4 temperature data"
  schedule    = var.nasa_gistemp_schedule
  time_zone   = var.time_zone
  project     = var.project_id
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = var.nasa_gistemp_function_url

    oidc_token {
      service_account_email = var.service_account_email
    }
  }

  retry_config {
    retry_count          = 3
    max_retry_duration   = "3600s"
    min_backoff_duration = "60s"
    max_backoff_duration = "600s"
  }
}
