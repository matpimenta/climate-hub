# Climate Data Platform Module

This Terraform module deploys infrastructure for ingesting climate data from public APIs into BigQuery.

## Features

- **BigQuery Dataset & Tables:** Partitioned and clustered tables for optimal query performance
- **Cloud Function:** Automated data ingestion from climate APIs
- **Cloud Scheduler:** Monthly scheduled execution
- **Error Handling:** Comprehensive retry logic and error tracking
- **Monitoring Ready:** Structured for Cloud Monitoring integration

## Architecture

```
API Source → Cloud Scheduler → Cloud Function → BigQuery
```

## Usage

```hcl
module "climate_data" {
  source = "../../modules/climate-data"

  project_id  = "my-project-id"
  region      = "us-central1"
  environment = "dev"
  name_prefix = "data-platform-dev"
  labels = {
    team = "data-engineering"
  }

  # BigQuery configuration
  bigquery_location          = "US"
  dataset_id                 = "climate_data"
  delete_contents_on_destroy = true

  # Cloud Functions configuration
  service_account_email = "cloud-functions@project.iam.gserviceaccount.com"
  source_bucket         = "my-source-bucket"

  # Scheduler configuration
  ingestion_schedule  = "0 2 5 * *"  # Monthly on 5th at 2 AM UTC
  ingestion_time_zone = "UTC"
}
```

## Data Sources

Currently implements the **Global Warming API** with 4 endpoints:
- Temperature anomalies (1880-present)
- CO2 concentrations
- Methane concentrations
- Nitrous oxide concentrations

## Outputs

- `dataset_id` - BigQuery dataset ID
- `table_ids` - Map of table names to full IDs
- `function_url` - Cloud Function HTTP trigger URL
- `scheduler_job_name` - Cloud Scheduler job name
- `scheduler_schedule` - Cron schedule

## Requirements

- Terraform >= 1.5.0
- Google Provider ~> 5.0
- Archive Provider (for function packaging)

## Resources Created

- 1 BigQuery dataset
- 4 BigQuery tables (partitioned by date)
- 1 Cloud Function (Python 3.11)
- 1 Cloud Scheduler job
- 1 GCS object (function source code)
- IAM bindings for function invocation

## Cost Estimate

~$1-2/month for monthly execution and minimal data storage.

## Testing

```bash
# Test the function manually
curl -X POST $(terraform output -raw climate_data_function_url)

# Query the data
bq query 'SELECT COUNT(*) FROM climate_data.raw_gw_temperature'
```
