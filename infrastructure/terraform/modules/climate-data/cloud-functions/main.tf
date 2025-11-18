# Cloud Functions for climate data ingestion
# This module deploys Cloud Functions to ingest climate data from public APIs

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

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Service account email for Cloud Functions"
  type        = string
}

variable "source_bucket" {
  description = "GCS bucket for Cloud Function source code"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID for climate data"
  type        = string
  default     = "climate_data"
}

# Create a zip file of the Cloud Function source code
data "archive_file" "global_warming_api_source" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/cloud-functions/global-warming-api-ingest"
  output_path = "${path.module}/global-warming-api-ingest.zip"
}

# Upload the function source code to GCS
resource "google_storage_bucket_object" "global_warming_api_source" {
  name   = "cloud-functions/global-warming-api-ingest-${data.archive_file.global_warming_api_source.output_md5}.zip"
  bucket = var.source_bucket
  source = data.archive_file.global_warming_api_source.output_path
}

# Deploy the Global Warming API ingestion Cloud Function
resource "google_cloudfunctions_function" "global_warming_api_ingest" {
  name        = "global-warming-api-ingest-${var.environment}"
  description = "Ingest climate data from Global Warming API into BigQuery"
  runtime     = "python311"
  project     = var.project_id
  region      = var.region

  available_memory_mb   = 512
  source_archive_bucket = var.source_bucket
  source_archive_object = google_storage_bucket_object.global_warming_api_source.name
  trigger_http          = true
  entry_point           = "ingest_global_warming_data"
  timeout               = 540

  service_account_email = var.service_account_email

  environment_variables = {
    GCP_PROJECT = var.project_id
    DATASET_ID  = var.dataset_id
  }

  labels = merge(var.labels, {
    function_type = "data_ingestion"
    data_source   = "global_warming_api"
  })
}

# Allow Cloud Scheduler to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.global_warming_api_ingest.project
  region         = google_cloudfunctions_function.global_warming_api_ingest.region
  cloud_function = google_cloudfunctions_function.global_warming_api_ingest.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${var.service_account_email}"
}

# Also allow unauthenticated invocation for testing (remove in prod)
resource "google_cloudfunctions_function_iam_member" "invoker_public" {
  count = var.environment == "dev" ? 1 : 0

  project        = google_cloudfunctions_function.global_warming_api_ingest.project
  region         = google_cloudfunctions_function.global_warming_api_ingest.region
  cloud_function = google_cloudfunctions_function.global_warming_api_ingest.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# =============================================================================
# NASA GISTEMP v4 CLOUD FUNCTION
# =============================================================================

# Create a zip file of the NASA GISTEMP function source code
data "archive_file" "nasa_gistemp_source" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/cloud-functions/nasa-gistemp-ingest"
  output_path = "${path.module}/nasa-gistemp-ingest.zip"
}

# Upload the function source code to GCS
resource "google_storage_bucket_object" "nasa_gistemp_source" {
  name   = "cloud-functions/nasa-gistemp-ingest-${data.archive_file.nasa_gistemp_source.output_md5}.zip"
  bucket = var.source_bucket
  source = data.archive_file.nasa_gistemp_source.output_path
}

# Deploy the NASA GISTEMP ingestion Cloud Function
resource "google_cloudfunctions_function" "nasa_gistemp_ingest" {
  name        = "nasa-gistemp-ingest-${var.environment}"
  description = "Ingest temperature data from NASA GISTEMP v4 into BigQuery"
  runtime     = "python311"
  project     = var.project_id
  region      = var.region

  available_memory_mb   = 512
  source_archive_bucket = var.source_bucket
  source_archive_object = google_storage_bucket_object.nasa_gistemp_source.name
  trigger_http          = true
  entry_point           = "ingest_gistemp_data"
  timeout               = 540

  service_account_email = var.service_account_email

  environment_variables = {
    GCP_PROJECT = var.project_id
    DATASET_ID  = var.dataset_id
  }

  labels = merge(var.labels, {
    function_type = "data_ingestion"
    data_source   = "nasa_gistemp"
  })
}

# Allow Cloud Scheduler to invoke the NASA GISTEMP function
resource "google_cloudfunctions_function_iam_member" "nasa_gistemp_invoker" {
  project        = google_cloudfunctions_function.nasa_gistemp_ingest.project
  region         = google_cloudfunctions_function.nasa_gistemp_ingest.region
  cloud_function = google_cloudfunctions_function.nasa_gistemp_ingest.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${var.service_account_email}"
}

# Allow unauthenticated invocation for testing (dev only)
resource "google_cloudfunctions_function_iam_member" "nasa_gistemp_invoker_public" {
  count = var.environment == "dev" ? 1 : 0

  project        = google_cloudfunctions_function.nasa_gistemp_ingest.project
  region         = google_cloudfunctions_function.nasa_gistemp_ingest.region
  cloud_function = google_cloudfunctions_function.nasa_gistemp_ingest.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
