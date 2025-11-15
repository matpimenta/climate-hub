# Module: cloud-functions
# Purpose: Cloud Functions for lightweight data connectors
# Status: Stub implementation - to be expanded

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Cloud Functions are typically deployed via application code deployment
# This module provides configuration placeholders
