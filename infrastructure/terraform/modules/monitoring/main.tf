# Module: monitoring
# Purpose: Cloud Monitoring alerts and dashboards
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

# Placeholder dashboard IDs
locals {
  dashboard_ids = {
    platform_health = "platform-health-dashboard"
    data_freshness  = "data-freshness-dashboard"
    cost_tracking   = "cost-tracking-dashboard"
  }
}
