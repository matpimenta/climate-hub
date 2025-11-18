# Outputs for the climate data module

output "dataset_id" {
  description = "BigQuery dataset ID for climate data"
  value       = module.bigquery.dataset_id
}

output "dataset_full_id" {
  description = "Full BigQuery dataset ID (project:dataset)"
  value       = module.bigquery.dataset_full_id
}

output "table_ids" {
  description = "Map of BigQuery table IDs"
  value       = module.bigquery.table_ids
}

output "function_name" {
  description = "Name of the Global Warming API Cloud Function"
  value       = module.cloud_functions.function_name
}

output "function_url" {
  description = "HTTP trigger URL for the Global Warming API function"
  value       = module.cloud_functions.function_url
}

output "nasa_gistemp_function_name" {
  description = "Name of the NASA GISTEMP Cloud Function"
  value       = module.cloud_functions.nasa_gistemp_function_name
}

output "nasa_gistemp_function_url" {
  description = "HTTP trigger URL for the NASA GISTEMP function"
  value       = module.cloud_functions.nasa_gistemp_function_url
}

output "scheduler_job_name" {
  description = "Name of the Global Warming API Cloud Scheduler job"
  value       = module.cloud_scheduler.job_name
}

output "scheduler_schedule" {
  description = "Cron schedule for Global Warming API ingestion"
  value       = module.cloud_scheduler.schedule
}

output "nasa_gistemp_scheduler_job_name" {
  description = "Name of the NASA GISTEMP Cloud Scheduler job"
  value       = module.cloud_scheduler.nasa_gistemp_job_name
}

output "nasa_gistemp_scheduler_schedule" {
  description = "Cron schedule for NASA GISTEMP ingestion"
  value       = module.cloud_scheduler.nasa_gistemp_schedule
}
