# GCP Data Platform - Variables for Development Environment

# ============================================================================
# PROJECT CONFIGURATION
# ============================================================================

variable "project_id" {
  description = "GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "data-platform"
}

# ============================================================================
# NETWORKING
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "dataflow_subnet_cidr" {
  description = "CIDR block for Dataflow subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "composer_subnet_cidr" {
  description = "CIDR block for Cloud Composer subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "cloud_run_subnet_cidr" {
  description = "CIDR block for Cloud Run subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

# ============================================================================
# STORAGE
# ============================================================================

variable "bronze_retention_days" {
  description = "Retention period for Bronze zone data (in days)"
  type        = number
  default     = 2555 # ~7 years
}

variable "silver_retention_days" {
  description = "Retention period for Silver zone data (in days)"
  type        = number
  default     = 1825 # ~5 years
}

variable "gold_retention_days" {
  description = "Retention period for Gold zone data (in days, -1 for infinite)"
  type        = number
  default     = -1 # Keep forever
}

variable "enable_cross_region_replication" {
  description = "Enable cross-region replication for Bronze zone (disaster recovery)"
  type        = bool
  default     = false # Disabled in dev for cost savings
}

# ============================================================================
# BIGQUERY
# ============================================================================

variable "bigquery_location" {
  description = "BigQuery location for datasets (US, EU, or region)"
  type        = string
  default     = "US"
}

# ============================================================================
# DATAFLOW
# ============================================================================

variable "dataflow_machine_type" {
  description = "Machine type for Dataflow workers"
  type        = string
  default     = "n1-standard-2"
}

variable "dataflow_max_workers" {
  description = "Maximum number of Dataflow workers"
  type        = number
  default     = 10
}

variable "enable_preemptible_workers" {
  description = "Use preemptible VMs for Dataflow workers (cost optimization)"
  type        = bool
  default     = true # Enabled in dev for cost savings
}

# ============================================================================
# CLOUD COMPOSER
# ============================================================================

variable "enable_composer" {
  description = "Enable Cloud Composer (managed Airflow) deployment"
  type        = bool
  default     = true
}

variable "composer_node_count" {
  description = "Number of Cloud Composer nodes"
  type        = number
  default     = 3
}

variable "composer_machine_type" {
  description = "Machine type for Cloud Composer nodes"
  type        = string
  default     = "n1-standard-2"
}

variable "composer_disk_size_gb" {
  description = "Disk size for Cloud Composer nodes (in GB)"
  type        = number
  default     = 30
}

# ============================================================================
# API GATEWAY
# ============================================================================

variable "enable_api_gateway" {
  description = "Enable API Gateway for third-party data access"
  type        = bool
  default     = true
}

variable "oauth_issuer" {
  description = "OAuth 2.0 issuer URL for API authentication"
  type        = string
  default     = "https://accounts.google.com"
}

variable "oauth_audiences" {
  description = "OAuth 2.0 audiences for API authentication"
  type        = list(string)
  default     = []
}

variable "api_rate_limit_rpm" {
  description = "API rate limit in requests per minute"
  type        = number
  default     = 1000
}

# ============================================================================
# VERTEX AI
# ============================================================================

variable "enable_vertex_ai" {
  description = "Enable Vertex AI Feature Store"
  type        = bool
  default     = false # Disabled in dev by default
}

variable "vertex_ai_node_count" {
  description = "Number of nodes for Vertex AI Feature Store online serving"
  type        = number
  default     = 1
}

# ============================================================================
# SECURITY
# ============================================================================

variable "enable_cmek" {
  description = "Enable Customer-Managed Encryption Keys (CMEK)"
  type        = bool
  default     = false # Disabled in dev for simplicity
}

# ============================================================================
# MONITORING
# ============================================================================

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "daily_cost_threshold" {
  description = "Daily cost threshold for cost alerts (in USD)"
  type        = number
  default     = 100
}

variable "data_freshness_sla_minutes" {
  description = "Data freshness SLA in minutes (alert if data is older)"
  type        = number
  default     = 120 # 2 hours
}
