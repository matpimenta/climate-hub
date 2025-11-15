# Module: cloud-run  
# Purpose: Cloud Run services for APIs and connectors
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google"; version = "~> 5.0" }
  }
}
