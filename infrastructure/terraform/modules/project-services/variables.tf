variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "services" {
  description = "List of GCP service APIs to enable"
  type        = list(string)
}
