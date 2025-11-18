# Climate Data Platform Module
# This module deploys the infrastructure for ingesting climate data from public APIs

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
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bigquery_location" {
  description = "BigQuery location for datasets"
  type        = string
  default     = "US"
}

variable "dataset_id" {
  description = "BigQuery dataset ID for climate data"
  type        = string
  default     = "climate_data"
}

variable "service_account_email" {
  description = "Service account email for Cloud Functions"
  type        = string
}

variable "source_bucket" {
  description = "GCS bucket for Cloud Function source code"
  type        = string
}

variable "delete_contents_on_destroy" {
  description = "Whether to delete BigQuery table contents on destroy"
  type        = bool
  default     = true
}

variable "global_warming_schedule" {
  description = "Cron schedule for Global Warming API data ingestion"
  type        = string
  default     = "0 2 5 * *" # Monthly on 5th at 2 AM UTC
}

variable "nasa_gistemp_schedule" {
  description = "Cron schedule for NASA GISTEMP data ingestion"
  type        = string
  default     = "0 3 15 * *" # Monthly on 15th at 3 AM UTC
}

variable "ingestion_time_zone" {
  description = "Time zone for ingestion schedule"
  type        = string
  default     = "UTC"
}

# ============================================================================
# BIGQUERY DATASETS AND TABLES
# ============================================================================

module "bigquery" {
  source = "./bigquery"

  project_id                 = var.project_id
  dataset_id                 = var.dataset_id
  location                   = var.bigquery_location
  labels                     = var.labels
  delete_contents_on_destroy = var.delete_contents_on_destroy
}

# ============================================================================
# CLOUD FUNCTIONS
# ============================================================================

module "cloud_functions" {
  source = "./cloud-functions"

  project_id            = var.project_id
  region                = var.region
  environment           = var.environment
  labels                = var.labels
  service_account_email = var.service_account_email
  source_bucket         = var.source_bucket
  dataset_id            = var.dataset_id

  depends_on = [module.bigquery]
}

# ============================================================================
# CLOUD SCHEDULER
# ============================================================================

module "cloud_scheduler" {
  source = "./cloud-scheduler"

  project_id                   = var.project_id
  region                       = var.region
  environment                  = var.environment
  global_warming_function_url  = module.cloud_functions.function_url
  nasa_gistemp_function_url    = module.cloud_functions.nasa_gistemp_function_url
  service_account_email        = var.service_account_email
  global_warming_schedule      = var.global_warming_schedule
  nasa_gistemp_schedule        = var.nasa_gistemp_schedule
  time_zone                    = var.ingestion_time_zone

  depends_on = [module.cloud_functions]
}
