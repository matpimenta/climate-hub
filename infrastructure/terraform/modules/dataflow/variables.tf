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

variable "network" {
  description = "VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork name"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for Dataflow jobs"
  type        = string
}

variable "staging_location" {
  description = "GCS location for staging files"
  type        = string
}

variable "temp_location" {
  description = "GCS location for temp files"
  type        = string
}

variable "machine_type" {
  description = "Machine type for workers"
  type        = string
  default     = "n1-standard-2"
}

variable "max_workers" {
  description = "Maximum number of workers"
  type        = number
  default     = 10
}

variable "use_preemptible_workers" {
  description = "Use preemptible workers"
  type        = bool
  default     = false
}

variable "ip_configuration" {
  description = "IP configuration for workers"
  type        = string
  default     = "WORKER_IP_PRIVATE"
}

variable "enable_streaming_engine" {
  description = "Enable Streaming Engine"
  type        = bool
  default     = true
}
