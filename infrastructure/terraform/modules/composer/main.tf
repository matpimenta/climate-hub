# Module: composer
# Purpose: Cloud Composer (managed Airflow) for orchestration
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google"; version = "~> 5.0" }
  }
}
