output "dataflow_config" {
  description = "Dataflow job configuration"
  value = {
    project_id               = var.project_id
    region                   = var.region
    network                  = var.network
    subnetwork               = var.subnetwork
    service_account          = var.service_account_email
    staging_location         = var.staging_location
    temp_location            = var.temp_location
    machine_type             = var.machine_type
    max_workers              = var.max_workers
    use_preemptible_workers  = var.use_preemptible_workers
    ip_configuration         = var.ip_configuration
    enable_streaming_engine  = var.enable_streaming_engine
  }
}

output "template_bucket" {
  description = "Dataflow template bucket"
  value       = google_storage_bucket.flex_templates.name
}
