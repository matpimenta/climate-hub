# GCP Data Platform - Development Environment
# This is the main Terraform configuration for the dev environment

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  # Backend configuration for storing Terraform state in GCS
  # Note: Backend configuration cannot use variables
  # The bucket name will be provided via -backend-config flag during init
  backend "gcs" {
    prefix = "environments/dev"
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Local variables for resource naming and tagging
locals {
  environment = "dev"
  common_labels = {
    environment = local.environment
    managed_by  = "terraform"
    project     = "data-platform"
    cost_center = var.cost_center
    team        = "data-engineering"
  }

  # Naming convention: {resource-type}-{project-name}-{environment}-{region}
  name_prefix = "data-platform-${local.environment}"
}

# ============================================================================
# PHASE 1: FOUNDATION
# ============================================================================

# Enable required GCP APIs
module "project_services" {
  source = "../../modules/project-services"

  project_id = var.project_id

  services = [
    "compute.googleapis.com",              # Compute Engine
    "storage-api.googleapis.com",          # Cloud Storage
    "storage-component.googleapis.com",    # Cloud Storage
    "bigquery.googleapis.com",             # BigQuery
    "bigquerystorage.googleapis.com",      # BigQuery Storage API
    "dataflow.googleapis.com",             # Dataflow
    "pubsub.googleapis.com",               # Pub/Sub
    "cloudfunctions.googleapis.com",       # Cloud Functions
    "run.googleapis.com",                  # Cloud Run
    "composer.googleapis.com",             # Cloud Composer
    "datacatalog.googleapis.com",          # Data Catalog
    "secretmanager.googleapis.com",        # Secret Manager
    "cloudkms.googleapis.com",             # Cloud KMS
    "iam.googleapis.com",                  # IAM
    "cloudresourcemanager.googleapis.com", # Resource Manager
    "monitoring.googleapis.com",           # Cloud Monitoring
    "logging.googleapis.com",              # Cloud Logging
    "cloudbuild.googleapis.com",           # Cloud Build
    "artifactregistry.googleapis.com",     # Artifact Registry
    "aiplatform.googleapis.com",           # Vertex AI
    "datastream.googleapis.com",           # Datastream
    "storagetransfer.googleapis.com",      # Storage Transfer Service
    "cloudscheduler.googleapis.com",       # Cloud Scheduler
    "serviceusage.googleapis.com",         # Service Usage API
  ]
}

# Networking: VPC, subnets, firewall rules
module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  vpc_cidr = var.vpc_cidr

  # Subnets for different components
  subnets = {
    dataflow = {
      cidr        = var.dataflow_subnet_cidr
      description = "Subnet for Dataflow workers"
      region      = var.region
    }
    composer = {
      cidr        = var.composer_subnet_cidr
      description = "Subnet for Cloud Composer"
      region      = var.region
    }
    cloud_run = {
      cidr        = var.cloud_run_subnet_cidr
      description = "Subnet for Cloud Run services"
      region      = var.region
    }
  }

  # Enable Private Google Access for API calls without public IPs
  enable_private_google_access = true

  # Enable VPC Flow Logs for network monitoring
  enable_flow_logs = var.enable_vpc_flow_logs

  depends_on = [module.project_services]
}

# Security: IAM, Secret Manager, KMS
module "security" {
  source = "../../modules/security"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Create service accounts for each component
  service_accounts = {
    dataflow = {
      display_name = "Dataflow Service Account"
      description  = "Service account for Dataflow jobs"
      roles = [
        "roles/dataflow.worker",
        "roles/storage.objectAdmin",
        "roles/bigquery.dataEditor",
        "roles/pubsub.editor",
      ]
    }
    cloud_functions = {
      display_name = "Cloud Functions Service Account"
      description  = "Service account for Cloud Functions connectors"
      roles = [
        "roles/cloudfunctions.invoker",
        "roles/pubsub.publisher",
        "roles/secretmanager.secretAccessor",
      ]
    }
    cloud_run = {
      display_name = "Cloud Run Service Account"
      description  = "Service account for Cloud Run services"
      roles = [
        "roles/run.invoker",
        "roles/pubsub.publisher",
        "roles/bigquery.dataViewer",
        "roles/secretmanager.secretAccessor",
      ]
    }
    composer = {
      display_name = "Cloud Composer Service Account"
      description  = "Service account for Cloud Composer"
      roles = [
        "roles/composer.worker",
        "roles/dataflow.admin",
        "roles/bigquery.admin",
        "roles/storage.objectAdmin",
      ]
    }
    api_server = {
      display_name = "API Server Service Account"
      description  = "Service account for API serving layer"
      roles = [
        "roles/bigquery.jobUser",
        "roles/bigquery.dataViewer",
      ]
    }
  }

  # Enable CMEK (Customer-Managed Encryption Keys) for sensitive data
  enable_cmek = var.enable_cmek

  # KMS key ring for encryption keys
  kms_key_ring_name = "${local.name_prefix}-keyring"

  # Crypto keys for different services
  kms_crypto_keys = var.enable_cmek ? {
    bigquery = {
      rotation_period = "7776000s" # 90 days
      purpose         = "ENCRYPT_DECRYPT"
    }
    storage = {
      rotation_period = "7776000s"
      purpose         = "ENCRYPT_DECRYPT"
    }
    pubsub = {
      rotation_period = "7776000s"
      purpose         = "ENCRYPT_DECRYPT"
    }
  } : {}

  depends_on = [module.project_services]
}

# Storage: GCS buckets for Bronze, Silver, Gold zones
module "storage" {
  source = "../../modules/storage"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Bronze zone - Raw data storage
  bronze_zone = {
    retention_days      = var.bronze_retention_days
    nearline_after_days = 90
    coldline_after_days = 365
    enable_versioning   = true
    enable_cross_region = var.enable_cross_region_replication
    storage_class       = "STANDARD"
  }

  # Silver zone - Processed data storage
  silver_zone = {
    retention_days      = var.silver_retention_days
    nearline_after_days = 180
    coldline_after_days = 730
    enable_versioning   = false
    enable_cross_region = false
    storage_class       = "STANDARD"
  }

  # Landing zone - Temporary file uploads
  landing_zone = {
    retention_days      = 7
    nearline_after_days = null
    coldline_after_days = null
    enable_versioning   = false
    enable_cross_region = false
    storage_class       = "STANDARD"
  }

  # Dataflow staging and temp buckets
  dataflow_staging = {
    retention_days      = 30
    nearline_after_days = null
    coldline_after_days = null
    enable_versioning   = false
    enable_cross_region = false
    storage_class       = "STANDARD"
  }

  # Encryption key from KMS (if CMEK enabled)
  encryption_key = var.enable_cmek ? module.security.kms_crypto_keys["storage"].id : null

  # Service accounts for IAM bindings
  dataflow_service_account        = module.security.service_accounts["dataflow"].email
  cloud_functions_service_account = module.security.service_accounts["cloud_functions"].email

  depends_on = [module.project_services, module.security]
}

# BigQuery: Datasets for Bronze, Silver, Gold zones
module "bigquery" {
  source = "../../modules/bigquery"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  location = var.bigquery_location

  # Create datasets for each zone
  datasets = {
    bronze = {
      description                     = "Bronze zone - Raw data from sources"
      delete_contents_on_destroy      = local.environment != "prod"
      default_partition_expiration_ms = null
      default_table_expiration_ms     = null
      access = [
        {
          role           = "OWNER"
          user_by_email  = null
          group_by_email = null
          special_group  = "projectOwners"
        },
        {
          role           = "WRITER"
          user_by_email  = module.security.service_accounts["dataflow"].email
          group_by_email = null
          special_group  = null
        }
      ]
    }

    silver = {
      description                     = "Silver zone - Cleaned and validated data"
      delete_contents_on_destroy      = local.environment != "prod"
      default_partition_expiration_ms = null
      default_table_expiration_ms     = null
      access = [
        {
          role           = "OWNER"
          user_by_email  = null
          group_by_email = null
          special_group  = "projectOwners"
        },
        {
          role           = "WRITER"
          user_by_email  = module.security.service_accounts["dataflow"].email
          group_by_email = null
          special_group  = null
        },
        {
          role           = "READER"
          user_by_email  = module.security.service_accounts["api_server"].email
          group_by_email = null
          special_group  = null
        }
      ]
    }

    gold = {
      description                     = "Gold zone - Business-ready curated data"
      delete_contents_on_destroy      = local.environment != "prod"
      default_partition_expiration_ms = null
      default_table_expiration_ms     = null
      access = [
        {
          role           = "OWNER"
          user_by_email  = null
          group_by_email = null
          special_group  = "projectOwners"
        },
        {
          role           = "WRITER"
          user_by_email  = module.security.service_accounts["dataflow"].email
          group_by_email = null
          special_group  = null
        },
        {
          role           = "READER"
          user_by_email  = module.security.service_accounts["api_server"].email
          group_by_email = null
          special_group  = null
        },
        {
          role           = "READER"
          user_by_email  = null
          group_by_email = null
          special_group  = "allAuthenticatedUsers"
        }
      ]
    }

    monitoring = {
      description                     = "Monitoring and metrics data"
      delete_contents_on_destroy      = true
      default_partition_expiration_ms = 2592000000 # 30 days
      default_table_expiration_ms     = null
      access = [
        {
          role           = "OWNER"
          user_by_email  = null
          group_by_email = null
          special_group  = "projectOwners"
        }
      ]
    }
  }

  # Encryption key from KMS (if CMEK enabled)
  encryption_key = var.enable_cmek ? module.security.kms_crypto_keys["bigquery"].id : null

  depends_on = [module.project_services, module.security]
}

# ============================================================================
# PHASE 2: EXTENSIBILITY - INGESTION & PROCESSING
# ============================================================================

# Pub/Sub: Topics and subscriptions for data ingestion
module "pubsub" {
  source = "../../modules/pubsub"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Create topics for different data sources
  topics = {
    # Generic ingestion topic
    data_ingestion = {
      description                = "Main topic for all data ingestion events"
      message_retention_duration = "604800s" # 7 days
      enable_message_ordering    = false
    }

    # Dead letter topic for failed messages
    data_ingestion_dlq = {
      description                = "Dead letter queue for failed ingestion messages"
      message_retention_duration = "1209600s" # 14 days
      enable_message_ordering    = false
    }

    # CDC events topic
    database_cdc = {
      description                = "Change Data Capture events from databases"
      message_retention_duration = "259200s" # 3 days
      enable_message_ordering    = true
    }

    # Real-time events
    streaming_events = {
      description                = "High-volume streaming events"
      message_retention_duration = "86400s" # 1 day
      enable_message_ordering    = false
    }

    # Pipeline notifications
    pipeline_notifications = {
      description                = "Notifications about pipeline status"
      message_retention_duration = "86400s" # 1 day
      enable_message_ordering    = false
    }
  }

  # Subscriptions for Dataflow jobs
  subscriptions = {
    data_ingestion_to_bronze = {
      topic                        = "data_ingestion"
      ack_deadline_seconds         = 600       # 10 minutes
      message_retention_duration   = "604800s" # 7 days
      retain_acked_messages        = false
      enable_exactly_once_delivery = true
      dead_letter_topic            = "data_ingestion_dlq"
      max_delivery_attempts        = 5
    }

    database_cdc_to_bronze = {
      topic                        = "database_cdc"
      ack_deadline_seconds         = 300       # 5 minutes
      message_retention_duration   = "259200s" # 3 days
      retain_acked_messages        = false
      enable_exactly_once_delivery = true
      dead_letter_topic            = "data_ingestion_dlq"
      max_delivery_attempts        = 5
    }

    streaming_events_to_bigquery = {
      topic                        = "streaming_events"
      ack_deadline_seconds         = 120      # 2 minutes
      message_retention_duration   = "86400s" # 1 day
      retain_acked_messages        = false
      enable_exactly_once_delivery = false # For high throughput
      dead_letter_topic            = "data_ingestion_dlq"
      max_delivery_attempts        = 5
    }
  }

  # Encryption key from KMS (if CMEK enabled)
  encryption_key = var.enable_cmek ? module.security.kms_crypto_keys["pubsub"].id : null

  # Dataflow service account for IAM bindings
  dataflow_service_account = module.security.service_accounts["dataflow"].email

  depends_on = [module.project_services, module.security]
}

# Dataflow: Templates and infrastructure for data processing
module "dataflow" {
  source = "../../modules/dataflow"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Network configuration
  network    = module.networking.vpc_network.name
  subnetwork = module.networking.subnets["dataflow"].name

  # Service account
  service_account_email = module.security.service_accounts["dataflow"].email

  # Staging and temp locations
  staging_location = "gs://${module.storage.buckets["dataflow_staging"].name}/staging"
  temp_location    = "gs://${module.storage.buckets["dataflow_staging"].name}/temp"

  # Worker configuration
  machine_type = var.dataflow_machine_type
  max_workers  = var.dataflow_max_workers

  # Use preemptible workers for cost savings in dev
  use_preemptible_workers = var.enable_preemptible_workers

  # IP configuration
  ip_configuration = "WORKER_IP_PRIVATE"

  # Enable Streaming Engine for better performance
  enable_streaming_engine = true

  depends_on = [
    module.project_services,
    module.networking,
    module.storage,
    module.security,
    module.pubsub
  ]
}

# Cloud Functions: Lightweight connectors
module "cloud_functions" {
  source = "../../modules/cloud-functions"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Service account
  service_account_email = module.security.service_accounts["cloud_functions"].email

  # Source code bucket
  source_bucket = module.storage.buckets["dataflow_staging"].name

  # VPC connector for private networking
  vpc_connector = module.networking.vpc_connector_id

  depends_on = [
    module.project_services,
    module.networking,
    module.storage,
    module.security
  ]
}

# Cloud Run: Containerized connectors and API services
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Service account
  service_account_email = module.security.service_accounts["cloud_run"].email

  # VPC configuration
  vpc_connector_id = module.networking.vpc_connector_id

  # Allow unauthenticated access for webhooks (specific services only)
  allow_unauthenticated = false

  depends_on = [
    module.project_services,
    module.networking,
    module.security
  ]
}

# ============================================================================
# PHASE 3: SERVING LAYER
# ============================================================================

# Cloud Composer: Orchestration with managed Airflow
module "composer" {
  source = "../../modules/composer"

  count = var.enable_composer ? 1 : 0

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Network configuration
  network    = module.networking.vpc_network.id
  subnetwork = module.networking.subnets["composer"].id

  # Service account
  service_account_email = module.security.service_accounts["composer"].email

  # Environment configuration
  node_count   = var.composer_node_count
  machine_type = var.composer_machine_type
  disk_size_gb = var.composer_disk_size_gb

  # Airflow configuration overrides
  airflow_config_overrides = {
    "webserver-dag_default_view"   = "graph"
    "webserver-dag_orientation"    = "TB"
    "core-load_examples"           = "False"
    "scheduler-catchup_by_default" = "False"
  }

  # Python packages
  pypi_packages = {
    "apache-beam[gcp]"         = ""
    "great-expectations"       = ""
    "google-cloud-datacatalog" = ""
  }

  depends_on = [
    module.project_services,
    module.networking,
    module.security
  ]
}

# API Gateway: REST API for third-party data access
module "api_gateway" {
  source = "../../modules/api-gateway"

  count = var.enable_api_gateway ? 1 : 0

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Backend service (Cloud Run API server)
  backend_service_url = module.cloud_run.api_service_url

  # OAuth configuration
  oauth_issuer    = var.oauth_issuer
  oauth_audiences = var.oauth_audiences

  # Rate limiting
  rate_limit_requests_per_minute = var.api_rate_limit_rpm

  depends_on = [
    module.project_services,
    module.cloud_run
  ]
}

# Vertex AI: Feature Store for ML
module "vertex_ai" {
  source = "../../modules/vertex-ai"

  count = var.enable_vertex_ai ? 1 : 0

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Feature store configuration
  feature_store_config = {
    online_serving_config = {
      fixed_node_count = var.vertex_ai_node_count
    }
  }

  # Encryption
  encryption_key = var.enable_cmek ? module.security.kms_crypto_keys["storage"].id : null

  depends_on = [
    module.project_services,
    module.security
  ]
}

# ============================================================================
# PHASE 4: GOVERNANCE & MONITORING
# ============================================================================

# Data Catalog: Metadata and schema registry
module "data_catalog" {
  source = "../../modules/data-catalog"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Taxonomy for data classification
  taxonomies = {
    data_sensitivity = {
      display_name = "Data Sensitivity"
      description  = "Classification of data by sensitivity level"
      policy_tags = [
        {
          display_name = "Public"
          description  = "Publicly available data"
        },
        {
          display_name = "Internal"
          description  = "Internal use only"
        },
        {
          display_name = "Confidential"
          description  = "Confidential business data"
        },
        {
          display_name = "PII"
          description  = "Personally Identifiable Information"
        }
      ]
    }
  }

  depends_on = [module.project_services]
}

# Monitoring: Alerts, dashboards, and SLOs
module "monitoring" {
  source = "../../modules/monitoring"

  project_id  = var.project_id
  region      = var.region
  environment = local.environment
  name_prefix = local.name_prefix
  labels      = local.common_labels

  # Notification channels
  notification_channels = var.notification_channels

  # Alert policies
  enable_pipeline_failure_alerts = true
  enable_data_freshness_alerts   = true
  enable_cost_alerts             = true
  enable_security_alerts         = true

  # Cost thresholds
  daily_cost_threshold = var.daily_cost_threshold

  # Data freshness SLA (in minutes)
  data_freshness_sla_minutes = var.data_freshness_sla_minutes

  depends_on = [
    module.project_services,
    module.bigquery,
    module.dataflow,
    module.pubsub
  ]
}
