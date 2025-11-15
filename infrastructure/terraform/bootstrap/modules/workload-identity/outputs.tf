# Workload Identity Federation Module Outputs

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
}

output "workload_identity_pool_name" {
  description = "Full resource name of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.github_actions.name
}

output "workload_identity_provider_id" {
  description = "ID of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.github_actions.workload_identity_pool_provider_id
}

output "workload_identity_provider_name" {
  description = "Full resource name of the Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.github_actions.name
}

output "project_number" {
  description = "GCP project number (used in GitHub Actions configuration)"
  value       = data.google_project.project.number
}

output "github_actions_config" {
  description = "Configuration values to use in GitHub Actions workflow"
  value = {
    workload_identity_provider = google_iam_workload_identity_pool_provider.github_actions.name
    service_account            = var.service_account_name
    project_id                 = var.project_id
  }
}
