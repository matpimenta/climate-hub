# GCP Data Platform - Outputs for Development Environment

# ============================================================================
# PROJECT INFORMATION
# ============================================================================

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "environment" {
  description = "Environment name"
  value       = "dev"
}

# ============================================================================
# NETWORKING
# ============================================================================

output "vpc_network" {
  description = "VPC network details"
  value = {
    name = module.networking.vpc_network.name
    id   = module.networking.vpc_network.id
  }
}

output "subnets" {
  description = "Subnet details"
  value = {
    dataflow = {
      name = module.networking.subnets["dataflow"].name
      cidr = module.networking.subnets["dataflow"].ip_cidr_range
    }
    composer = {
      name = module.networking.subnets["composer"].name
      cidr = module.networking.subnets["composer"].ip_cidr_range
    }
    cloud_run = {
      name = module.networking.subnets["cloud_run"].name
      cidr = module.networking.subnets["cloud_run"].ip_cidr_range
    }
  }
}

# ============================================================================
# STORAGE
# ============================================================================

output "storage_buckets" {
  description = "GCS bucket names and URLs"
  value = {
    bronze = {
      name = module.storage.buckets["bronze"].name
      url  = module.storage.buckets["bronze"].url
    }
    silver = {
      name = module.storage.buckets["silver"].name
      url  = module.storage.buckets["silver"].url
    }
    landing = {
      name = module.storage.buckets["landing"].name
      url  = module.storage.buckets["landing"].url
    }
    dataflow_staging = {
      name = module.storage.buckets["dataflow_staging"].name
      url  = module.storage.buckets["dataflow_staging"].url
    }
  }
}

# ============================================================================
# BIGQUERY
# ============================================================================

output "bigquery_datasets" {
  description = "BigQuery dataset IDs"
  value = {
    bronze     = module.bigquery.datasets["bronze"].dataset_id
    silver     = module.bigquery.datasets["silver"].dataset_id
    gold       = module.bigquery.datasets["gold"].dataset_id
    monitoring = module.bigquery.datasets["monitoring"].dataset_id
  }
}

output "bigquery_connection_strings" {
  description = "BigQuery connection strings"
  value = {
    bronze     = "${var.project_id}.${module.bigquery.datasets["bronze"].dataset_id}"
    silver     = "${var.project_id}.${module.bigquery.datasets["silver"].dataset_id}"
    gold       = "${var.project_id}.${module.bigquery.datasets["gold"].dataset_id}"
    monitoring = "${var.project_id}.${module.bigquery.datasets["monitoring"].dataset_id}"
  }
}

# ============================================================================
# PUB/SUB
# ============================================================================

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value = {
    data_ingestion         = module.pubsub.topics["data_ingestion"].name
    data_ingestion_dlq     = module.pubsub.topics["data_ingestion_dlq"].name
    database_cdc           = module.pubsub.topics["database_cdc"].name
    streaming_events       = module.pubsub.topics["streaming_events"].name
    pipeline_notifications = module.pubsub.topics["pipeline_notifications"].name
  }
}

output "pubsub_subscriptions" {
  description = "Pub/Sub subscription names"
  value = {
    data_ingestion_to_bronze     = module.pubsub.subscriptions["data_ingestion_to_bronze"].name
    database_cdc_to_bronze       = module.pubsub.subscriptions["database_cdc_to_bronze"].name
    streaming_events_to_bigquery = module.pubsub.subscriptions["streaming_events_to_bigquery"].name
  }
}

# ============================================================================
# SERVICE ACCOUNTS
# ============================================================================

output "service_accounts" {
  description = "Service account email addresses"
  value = {
    dataflow        = module.security.service_accounts["dataflow"].email
    cloud_functions = module.security.service_accounts["cloud_functions"].email
    cloud_run       = module.security.service_accounts["cloud_run"].email
    composer        = module.security.service_accounts["composer"].email
    api_server      = module.security.service_accounts["api_server"].email
  }
  sensitive = false
}

# ============================================================================
# DATAFLOW
# ============================================================================

output "dataflow_config" {
  description = "Dataflow configuration"
  value = {
    staging_location = "gs://${module.storage.buckets["dataflow_staging"].name}/staging"
    temp_location    = "gs://${module.storage.buckets["dataflow_staging"].name}/temp"
    network          = module.networking.vpc_network.name
    subnetwork       = module.networking.subnets["dataflow"].name
    service_account  = module.security.service_accounts["dataflow"].email
  }
}

# ============================================================================
# CLOUD COMPOSER
# ============================================================================

output "composer_environment" {
  description = "Cloud Composer environment details"
  value = var.enable_composer ? {
    name           = module.composer[0].environment_name
    airflow_uri    = module.composer[0].airflow_uri
    gcs_bucket     = module.composer[0].gcs_bucket
    dag_gcs_prefix = module.composer[0].dag_gcs_prefix
  } : null
}

# ============================================================================
# API GATEWAY
# ============================================================================

output "api_gateway_url" {
  description = "API Gateway URL for third-party access"
  value       = var.enable_api_gateway ? module.api_gateway[0].gateway_url : null
}

# ============================================================================
# VERTEX AI
# ============================================================================

output "vertex_ai_feature_store" {
  description = "Vertex AI Feature Store details"
  value = var.enable_vertex_ai ? {
    name     = module.vertex_ai[0].feature_store_name
    location = var.region
  } : null
}

# ============================================================================
# MONITORING
# ============================================================================

output "monitoring_dashboards" {
  description = "Cloud Monitoring dashboard URLs"
  value = {
    platform_health = "https://console.cloud.google.com/monitoring/dashboards/custom/${module.monitoring.dashboard_ids["platform_health"]}"
    data_freshness  = "https://console.cloud.google.com/monitoring/dashboards/custom/${module.monitoring.dashboard_ids["data_freshness"]}"
    cost_tracking   = "https://console.cloud.google.com/monitoring/dashboards/custom/${module.monitoring.dashboard_ids["cost_tracking"]}"
  }
}

# ============================================================================
# QUICK START COMMANDS
# ============================================================================

output "quick_start_commands" {
  description = "Useful commands to get started"
  value       = <<-EOT
    # List storage buckets
    gcloud storage ls --project=${var.project_id}

    # Access BigQuery datasets
    bq ls --project_id=${var.project_id}

    # View Pub/Sub topics
    gcloud pubsub topics list --project=${var.project_id}

    # Access Cloud Composer Airflow UI
    ${var.enable_composer ? "gcloud composer environments describe ${module.composer[0].environment_name} --location=${var.region} --format=\"get(config.airflowUri)\"" : "# Composer not enabled"}

    # View monitoring dashboards
    echo "Platform Health: https://console.cloud.google.com/monitoring/dashboards/custom/${module.monitoring.dashboard_ids["platform_health"]}"

    # Upload file to landing zone
    gcloud storage cp <local-file> gs://${module.storage.buckets["landing"].name}/

    # Query Gold dataset
    bq query --use_legacy_sql=false 'SELECT * FROM `${var.project_id}.${module.bigquery.datasets["gold"].dataset_id}.<table>` LIMIT 10'
  EOT
}

# ============================================================================
# CONNECTION INFO FOR CICD
# ============================================================================

output "cicd_variables" {
  description = "Variables for CI/CD pipelines"
  value = {
    PROJECT_ID                      = var.project_id
    REGION                          = var.region
    BRONZE_BUCKET                   = module.storage.buckets["bronze"].name
    SILVER_BUCKET                   = module.storage.buckets["silver"].name
    LANDING_BUCKET                  = module.storage.buckets["landing"].name
    DATAFLOW_STAGING_BUCKET         = module.storage.buckets["dataflow_staging"].name
    BIGQUERY_DATASET_BRONZE         = module.bigquery.datasets["bronze"].dataset_id
    BIGQUERY_DATASET_SILVER         = module.bigquery.datasets["silver"].dataset_id
    BIGQUERY_DATASET_GOLD           = module.bigquery.datasets["gold"].dataset_id
    PUBSUB_TOPIC_INGESTION          = module.pubsub.topics["data_ingestion"].name
    DATAFLOW_SERVICE_ACCOUNT        = module.security.service_accounts["dataflow"].email
    CLOUD_FUNCTIONS_SERVICE_ACCOUNT = module.security.service_accounts["cloud_functions"].email
  }
  sensitive = false
}

# ============================================================================
# CLIMATE DATA PLATFORM
# ============================================================================

output "climate_data" {
  description = "Climate data platform details"
  value = {
    dataset_id        = module.climate_data.dataset_id
    dataset_full_id   = module.climate_data.dataset_full_id
    tables            = module.climate_data.table_ids
    function_name     = module.climate_data.function_name
    function_url      = module.climate_data.function_url
    scheduler_job     = module.climate_data.scheduler_job_name
    ingestion_schedule = module.climate_data.scheduler_schedule
  }
}

output "climate_data_quick_commands" {
  description = "Quick commands for climate data platform"
  value = <<-EOT
    # Query climate data
    bq query --use_legacy_sql=false 'SELECT * FROM `${module.climate_data.dataset_full_id}.raw_gw_temperature` ORDER BY measurement_date DESC LIMIT 10'

    # Manually trigger climate data ingestion
    curl -X POST ${module.climate_data.function_url}

    # View Cloud Function logs
    gcloud functions logs read ${module.climate_data.function_name} --region=${var.region} --limit=50

    # Check BigQuery tables
    bq ls ${module.climate_data.dataset_id}

    # View scheduler job details
    gcloud scheduler jobs describe ${module.climate_data.scheduler_job_name} --location=${var.region}
  EOT
}
