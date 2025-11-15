variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "BigQuery location (US, EU, or region)"
  type        = string
  default     = "US"
}

variable "datasets" {
  description = "Map of BigQuery datasets to create"
  type = map(object({
    description                     = string
    delete_contents_on_destroy      = bool
    default_partition_expiration_ms = number
    default_table_expiration_ms     = number
    access = list(object({
      role           = string
      user_by_email  = string
      group_by_email = string
      special_group  = string
    }))
  }))
}

variable "encryption_key" {
  description = "KMS encryption key ID for BigQuery"
  type        = string
  default     = null
}
