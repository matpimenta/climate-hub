# Workload Identity Federation Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "pool_id" {
  description = "ID for the Workload Identity Pool"
  type        = string
  default     = "github-actions-pool"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,30}[a-z0-9]$", var.pool_id))
    error_message = "Pool ID must be 6-32 characters, lowercase letters, digits, or hyphens."
  }
}

variable "pool_display_name" {
  description = "Display name for the Workload Identity Pool"
  type        = string
  default     = "GitHub Actions Pool"
}

variable "pool_description" {
  description = "Description of the Workload Identity Pool"
  type        = string
  default     = "Workload Identity Pool for GitHub Actions authentication"
}

variable "provider_id" {
  description = "ID for the Workload Identity Provider"
  type        = string
  default     = "github-actions-provider"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,30}[a-z0-9]$", var.provider_id))
    error_message = "Provider ID must be 6-32 characters, lowercase letters, digits, or hyphens."
  }
}

variable "provider_display_name" {
  description = "Display name for the Workload Identity Provider"
  type        = string
  default     = "GitHub Actions Provider"
}

variable "provider_description" {
  description = "Description of the Workload Identity Provider"
  type        = string
  default     = "OIDC provider for GitHub Actions"
}

variable "service_account_name" {
  description = "Fully qualified name of the service account to grant workload identity permissions (e.g., projects/PROJECT_ID/serviceAccounts/EMAIL)"
  type        = string
}

variable "repository_owner" {
  description = "GitHub repository owner (user or organization) - restricts access to repos under this owner"
  type        = string
}

variable "specific_repository" {
  description = "Specific repository to allow (e.g., 'owner/repo') - if not set, allows all repos under repository_owner"
  type        = string
  default     = null
}

variable "allowed_repositories" {
  description = "Additional specific repositories to allow (format: 'owner/repo')"
  type        = list(string)
  default     = []
}

variable "allowed_audiences" {
  description = "List of allowed audiences for OIDC tokens"
  type        = list(string)
  default     = []
}
