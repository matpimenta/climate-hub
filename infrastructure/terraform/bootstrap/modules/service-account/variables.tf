# Service Account Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "account_id" {
  description = "Service account ID (unique identifier)"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.account_id))
    error_message = "Service account ID must be 6-30 characters, lowercase letters, digits, or hyphens."
  }
}

variable "display_name" {
  description = "Display name for the service account"
  type        = string
  default     = "GitHub Actions Terraform Deployer"
}

variable "description" {
  description = "Description of the service account"
  type        = string
  default     = "Service account for deploying Terraform infrastructure via GitHub Actions"
}

variable "project_roles" {
  description = "List of project-level IAM roles to grant to the service account"
  type        = list(string)
  default = [
    "roles/editor",
    "roles/iam.securityAdmin",
    "roles/resourcemanager.projectIamAdmin",
  ]
}

variable "create_custom_role" {
  description = "Whether to create a custom IAM role with specific permissions"
  type        = bool
  default     = false
}

variable "custom_role_id" {
  description = "ID for the custom IAM role"
  type        = string
  default     = "terraformDeployer"
}

variable "custom_role_title" {
  description = "Title for the custom IAM role"
  type        = string
  default     = "Terraform Deployer"
}

variable "custom_role_permissions" {
  description = "List of permissions for the custom IAM role"
  type        = list(string)
  default     = []
}

variable "create_key" {
  description = "Whether to create a service account key (not recommended - use Workload Identity instead)"
  type        = bool
  default     = false
}
