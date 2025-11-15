# Module: dataflow
# Purpose: Dataflow job configuration and infrastructure
# Note: Dataflow jobs are typically deployed via templates at runtime
# This module provides the configuration values needed by jobs

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Dataflow template storage bucket
resource "google_storage_bucket" "flex_templates" {
  name          = "${var.name_prefix}-dataflow-templates"
  project       = var.project_id
  location      = var.region
  force_destroy = var.environment != "prod"

  uniform_bucket_level_access = true

  labels = var.labels
}

# No actual Dataflow jobs created here - they are deployed at runtime
# This module just outputs the configuration needed
