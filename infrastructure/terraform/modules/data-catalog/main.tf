# Module: data-catalog
# Purpose: Data Catalog for metadata and schema registry
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google"; version = "~> 5.0" }
  }
}
