# State Bucket Module Outputs

output "bucket_name" {
  description = "Name of the created state bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "bucket_url" {
  description = "URL of the state bucket"
  value       = google_storage_bucket.terraform_state.url
}

output "bucket_self_link" {
  description = "Self link of the state bucket"
  value       = google_storage_bucket.terraform_state.self_link
}

output "bucket_location" {
  description = "Location of the state bucket"
  value       = google_storage_bucket.terraform_state.location
}
