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

variable "bronze_zone" {
  description = "Bronze zone configuration"
  type = object({
    retention_days      = number
    nearline_after_days = number
    coldline_after_days = number
    enable_versioning   = bool
    enable_cross_region = bool
    storage_class       = string
  })
}

variable "silver_zone" {
  description = "Silver zone configuration"
  type = object({
    retention_days      = number
    nearline_after_days = number
    coldline_after_days = number
    enable_versioning   = bool
    enable_cross_region = bool
    storage_class       = string
  })
}

variable "landing_zone" {
  description = "Landing zone configuration"
  type = object({
    retention_days      = number
    nearline_after_days = number
    coldline_after_days = number
    enable_versioning   = bool
    enable_cross_region = bool
    storage_class       = string
  })
}

variable "dataflow_staging" {
  description = "Dataflow staging configuration"
  type = object({
    retention_days      = number
    nearline_after_days = number
    coldline_after_days = number
    enable_versioning   = bool
    enable_cross_region = bool
    storage_class       = string
  })
}

variable "encryption_key" {
  description = "KMS encryption key ID"
  type        = string
  default     = null
}

variable "enable_pubsub_notifications" {
  description = "Enable Pub/Sub notifications for bucket events"
  type        = bool
  default     = false
}

variable "pubsub_topic_id" {
  description = "Pub/Sub topic ID for bucket notifications"
  type        = string
  default     = null
}

variable "dataflow_service_account" {
  description = "Dataflow service account email"
  type        = string
  default     = ""
}

variable "cloud_functions_service_account" {
  description = "Cloud Functions service account email"
  type        = string
  default     = ""
}
