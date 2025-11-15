# State Bucket Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket for Terraform state"
  type        = string
}

variable "location" {
  description = "GCS bucket location"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "force_destroy" {
  description = "Allow destroying bucket even if it contains objects (use with caution)"
  type        = bool
  default     = false
}

variable "versioning_retention_count" {
  description = "Number of noncurrent versions to retain before deletion"
  type        = number
  default     = 10
}

variable "noncurrent_version_retention_days" {
  description = "Number of days to retain noncurrent versions"
  type        = number
  default     = 30
}

variable "encryption_key" {
  description = "KMS key for customer-managed encryption (optional)"
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to the bucket"
  type        = map(string)
  default     = {}
}
