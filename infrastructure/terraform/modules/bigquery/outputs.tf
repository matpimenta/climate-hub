output "datasets" {
  description = "Map of BigQuery dataset resources"
  value       = google_bigquery_dataset.datasets
}

output "dataset_ids" {
  description = "Map of dataset IDs"
  value = {
    for k, v in google_bigquery_dataset.datasets : k => v.dataset_id
  }
}

output "dataset_fully_qualified_names" {
  description = "Map of fully qualified dataset names"
  value = {
    for k, v in google_bigquery_dataset.datasets : k => "${var.project_id}.${v.dataset_id}"
  }
}
