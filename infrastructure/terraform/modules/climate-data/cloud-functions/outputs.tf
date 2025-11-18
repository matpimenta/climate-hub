# Outputs for climate data Cloud Functions module

# Global Warming API outputs
output "function_name" {
  description = "Name of the Global Warming API ingestion function"
  value       = google_cloudfunctions_function.global_warming_api_ingest.name
}

output "function_url" {
  description = "HTTP trigger URL for the Global Warming API ingestion function"
  value       = google_cloudfunctions_function.global_warming_api_ingest.https_trigger_url
}

output "function_id" {
  description = "Full ID of the Global Warming API ingestion function"
  value       = google_cloudfunctions_function.global_warming_api_ingest.id
}

# NASA GISTEMP outputs
output "nasa_gistemp_function_name" {
  description = "Name of the NASA GISTEMP ingestion function"
  value       = google_cloudfunctions_function.nasa_gistemp_ingest.name
}

output "nasa_gistemp_function_url" {
  description = "HTTP trigger URL for the NASA GISTEMP ingestion function"
  value       = google_cloudfunctions_function.nasa_gistemp_ingest.https_trigger_url
}

output "nasa_gistemp_function_id" {
  description = "Full ID of the NASA GISTEMP ingestion function"
  value       = google_cloudfunctions_function.nasa_gistemp_ingest.id
}
