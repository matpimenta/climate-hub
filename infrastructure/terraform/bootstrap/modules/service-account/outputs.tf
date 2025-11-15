# Service Account Module Outputs

output "service_account_email" {
  description = "Email address of the service account"
  value       = google_service_account.github_actions.email
}

output "service_account_name" {
  description = "Fully qualified name of the service account"
  value       = google_service_account.github_actions.name
}

output "service_account_id" {
  description = "ID of the service account"
  value       = google_service_account.github_actions.account_id
}

output "service_account_unique_id" {
  description = "Unique ID of the service account"
  value       = google_service_account.github_actions.unique_id
}

output "service_account_key" {
  description = "Service account key (if created) - SENSITIVE"
  value       = var.create_key ? google_service_account_key.github_actions_key[0].private_key : null
  sensitive   = true
}
