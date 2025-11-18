# Outputs for climate data Cloud Scheduler module

# Global Warming API job outputs
output "job_name" {
  description = "Name of the Global Warming API Cloud Scheduler job"
  value       = google_cloud_scheduler_job.global_warming_api_monthly.name
}

output "job_id" {
  description = "Full ID of the Global Warming API Cloud Scheduler job"
  value       = google_cloud_scheduler_job.global_warming_api_monthly.id
}

output "schedule" {
  description = "Cron schedule of the Global Warming API job"
  value       = google_cloud_scheduler_job.global_warming_api_monthly.schedule
}

# NASA GISTEMP job outputs
output "nasa_gistemp_job_name" {
  description = "Name of the NASA GISTEMP Cloud Scheduler job"
  value       = google_cloud_scheduler_job.nasa_gistemp_monthly.name
}

output "nasa_gistemp_job_id" {
  description = "Full ID of the NASA GISTEMP Cloud Scheduler job"
  value       = google_cloud_scheduler_job.nasa_gistemp_monthly.id
}

output "nasa_gistemp_schedule" {
  description = "Cron schedule of the NASA GISTEMP job"
  value       = google_cloud_scheduler_job.nasa_gistemp_monthly.schedule
}
