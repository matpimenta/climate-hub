# Module: project-services
# Purpose: Enable required GCP APIs for the data platform

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Enable required GCP APIs
resource "google_project_service" "services" {
  for_each = toset(var.services)

  project = var.project_id
  service = each.value

  # Don't disable the service if this resource is destroyed
  disable_on_destroy = false

  # Disable dependent services when disabling this service
  disable_dependent_services = false

  # Wait for service to be fully enabled
  timeouts {
    create = "30m"
    update = "40m"
  }
}
