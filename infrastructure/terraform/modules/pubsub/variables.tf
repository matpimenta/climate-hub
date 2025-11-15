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

variable "topics" {
  description = "Map of Pub/Sub topics to create"
  type = map(object({
    description                = string
    message_retention_duration = string
    enable_message_ordering    = bool
  }))
}

variable "subscriptions" {
  description = "Map of Pub/Sub subscriptions to create"
  type = map(object({
    topic                        = string
    ack_deadline_seconds         = number
    message_retention_duration   = string
    retain_acked_messages        = bool
    enable_exactly_once_delivery = bool
    dead_letter_topic            = string
    max_delivery_attempts        = number
  }))
}

variable "encryption_key" {
  description = "KMS encryption key ID"
  type        = string
  default     = null
}

variable "dataflow_service_account" {
  description = "Dataflow service account email"
  type        = string
  default     = ""
}
