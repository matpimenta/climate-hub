# Climate Data Ingestion Guide for GCP

**Version:** 1.0
**Last Updated:** 2025-11-14
**Target Platform:** Google Cloud Platform (GCP)
**Author:** Data Engineering Team

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Dataset-Specific Implementation](#dataset-specific-implementation)
4. [Phased Implementation Approach](#phased-implementation-approach)
5. [Infrastructure as Code](#infrastructure-as-code)
6. [Monitoring and Alerting](#monitoring-and-alerting)
7. [Cost Estimation](#cost-estimation)
8. [Testing Strategy](#testing-strategy)
9. [Appendix](#appendix)

---

## Executive Summary

This guide provides production-ready instructions for ingesting five climate datasets into a GCP-based data platform. The implementation leverages BigQuery for storage and analytics, Cloud Functions for lightweight extraction, Dataflow for complex transformations, Cloud Scheduler for orchestration, and Cloud Monitoring for observability.

### Datasets Overview

| Dataset | Complexity | Priority | Estimated Effort |
|---------|-----------|----------|------------------|
| Global Warming API | VERY LOW | Quick Win | 1-2 days |
| NASA GISTEMP v4 | LOW | Quick Win | 2-3 days |
| Our World in Data CO2 | LOW | Quick Win | 2-3 days |
| NOAA CDO API | MEDIUM | Core Production | 5-7 days |
| Copernicus ERA5 | HIGH | Core Production | 10-14 days |

**Total Estimated Effort:** 20-29 days for full implementation

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          DATA SOURCES                                │
├──────────────┬──────────────┬──────────────┬──────────────┬─────────┤
│ Global       │ NASA         │ OWID         │ NOAA         │ Copernicus│
│ Warming API  │ GISTEMP      │ CO2 Data     │ CDO API      │ ERA5      │
└──────┬───────┴──────┬───────┴──────┬───────┴──────┬───────┴─────┬───┘
       │              │              │              │             │
       ├──────────────┴──────────────┴──────────────┴─────────────┤
       │                                                            │
       ▼                                                            ▼
┌─────────────────┐                                      ┌─────────────────┐
│ Cloud Scheduler │                                      │ Pub/Sub Topics  │
│  (Cron Jobs)    │                                      │ (Event-Driven)  │
└────────┬────────┘                                      └────────┬────────┘
         │                                                        │
         ▼                                                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        INGESTION LAYER                                  │
├─────────────────────┬──────────────────────┬───────────────────────────┤
│  Cloud Functions    │   Cloud Functions    │    Dataflow Pipeline      │
│  (HTTP Extract)     │   (API Extract)      │    (Complex Transform)    │
│  - GISTEMP          │   - Global Warming   │    - ERA5 NetCDF          │
│  - OWID CO2         │   - NOAA CDO         │    - Large datasets       │
└──────────┬──────────┴──────────┬───────────┴────────────┬──────────────┘
           │                     │                        │
           ▼                     ▼                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   STAGING LAYER (Cloud Storage)                         │
│  - Raw data landing zone                                                │
│  - Lifecycle policies: 30-day retention                                 │
│  - Bucket: gs://[PROJECT]-climate-data-staging                          │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    DATA QUALITY & VALIDATION                            │
│  - Schema validation                                                    │
│  - Data freshness checks                                                │
│  - Anomaly detection                                                    │
│  - Referential integrity                                                │
└─────────────────────────────────┬──────────────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    DATA WAREHOUSE (BigQuery)                            │
├────────────────────┬────────────────────┬──────────────────────────────┤
│  RAW Layer         │  STAGING Layer     │  MART Layer                  │
│  - raw_gistemp     │  - stg_temperature │  - fact_climate_daily        │
│  - raw_noaa_cdo    │  - stg_emissions   │  - fact_climate_monthly      │
│  - raw_owid_co2    │  - stg_weather     │  - dim_station               │
│  - raw_era5        │  - stg_reanalysis  │  - dim_location              │
│  - raw_gw_api      │                    │  - agg_climate_trends        │
└────────────────────┴────────────────────┴──────────────────────────────┘
                                  │
                                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                    MONITORING & ALERTING                                │
│  - Cloud Monitoring Dashboards                                          │
│  - Pipeline success/failure alerts                                      │
│  - Data freshness alerts                                                │
│  - Cost anomaly detection                                               │
└────────────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Idempotency:** All pipelines support re-running without duplicates
2. **Incremental Processing:** Load only new/changed data when possible
3. **Data Lineage:** Track data source, ingestion time, and processing metadata
4. **Cost Optimization:** Partition by date, cluster by query patterns, use lifecycle policies
5. **Observability:** Comprehensive logging, metrics, and alerting
6. **Security:** API keys in Secret Manager, least-privilege IAM, VPC-SC ready

---

## Dataset-Specific Implementation

### Dataset 1: Global Warming API (VERY LOW Complexity)

#### Overview
- **Source:** https://global-warming.org/api/
- **Format:** JSON (REST API)
- **Update Frequency:** Monthly to quasi-daily
- **Authentication:** None
- **Endpoints:**
  - `/temperature-api` - Temperature anomalies
  - `/co2-api` - CO2 concentrations
  - `/methane-api` - CH4 concentrations
  - `/nitrous-oxide-api` - N2O concentrations

#### BigQuery Schema Design

```sql
-- Dataset: climate_data
-- Table: raw_global_warming_api

CREATE SCHEMA IF NOT EXISTS climate_data
OPTIONS(
  location='us',
  description='Climate data warehouse'
);

-- Temperature anomalies table
CREATE OR REPLACE TABLE climate_data.raw_gw_temperature (
  record_id STRING NOT NULL,
  measurement_date DATE NOT NULL,
  land FLOAT64,
  station FLOAT64,
  time STRING,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY measurement_date
CLUSTER BY ingestion_timestamp
OPTIONS(
  description='Global temperature anomalies from Global Warming API',
  require_partition_filter=FALSE,
  partition_expiration_days=NULL
);

-- CO2 concentrations table
CREATE OR REPLACE TABLE climate_data.raw_gw_co2 (
  record_id STRING NOT NULL,
  measurement_date DATE NOT NULL,
  cycle FLOAT64,
  trend FLOAT64,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY measurement_date
CLUSTER BY ingestion_timestamp
OPTIONS(
  description='CO2 concentrations from Global Warming API'
);

-- Methane concentrations table
CREATE OR REPLACE TABLE climate_data.raw_gw_methane (
  record_id STRING NOT NULL,
  measurement_date DATE NOT NULL,
  average FLOAT64,
  trend FLOAT64,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY measurement_date
CLUSTER BY ingestion_timestamp
OPTIONS(
  description='Methane concentrations from Global Warming API'
);

-- Nitrous oxide concentrations table
CREATE OR REPLACE TABLE climate_data.raw_gw_nitrous_oxide (
  record_id STRING NOT NULL,
  measurement_date DATE NOT NULL,
  average FLOAT64,
  trend FLOAT64,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY measurement_date
CLUSTER BY ingestion_timestamp
OPTIONS(
  description='Nitrous oxide concentrations from Global Warming API'
);
```

#### Data Pipeline Architecture

**Components:**
- **Cloud Scheduler:** Trigger monthly on 5th (after data updates)
- **Cloud Function (Python 3.11):** HTTP-triggered extraction and load
- **BigQuery:** Target warehouse

**Pipeline Flow:**
```
Cloud Scheduler → Cloud Function → BigQuery
                       ↓
                  Cloud Logging
```

#### Implementation Code

**Cloud Function: `global_warming_api_ingest`**

`main.py`:
```python
import functions_framework
import requests
from google.cloud import bigquery
from datetime import datetime, date
import hashlib
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = 'YOUR_PROJECT_ID'
DATASET_ID = 'climate_data'

API_ENDPOINTS = {
    'temperature': {
        'url': 'https://global-warming.org/api/temperature-api',
        'table': 'raw_gw_temperature',
        'fields': ['time', 'station', 'land']
    },
    'co2': {
        'url': 'https://global-warming.org/api/co2-api',
        'table': 'raw_gw_co2',
        'fields': ['time', 'cycle', 'trend']
    },
    'methane': {
        'url': 'https://global-warming.org/api/methane-api',
        'table': 'raw_gw_methane',
        'fields': ['time', 'average', 'trend']
    },
    'nitrous-oxide': {
        'url': 'https://global-warming.org/api/nitrous-oxide-api',
        'table': 'raw_gw_nitrous_oxide',
        'fields': ['time', 'average', 'trend']
    }
}

def generate_record_id(endpoint_name: str, time_value: str) -> str:
    """Generate unique record ID"""
    composite = f"{endpoint_name}_{time_value}"
    return hashlib.md5(composite.encode()).hexdigest()

def parse_time_to_date(time_str: str) -> date:
    """Parse time string to date (format: YYYY-MM-DD or YYYY.MMDD)"""
    try:
        # Handle decimal format (e.g., "1880.0417")
        if '.' in time_str:
            year = int(float(time_str))
            month_day = float(time_str) - year
            month = int(month_day * 12) + 1
            return date(year, month, 1)
        else:
            return datetime.strptime(time_str, '%Y-%m-%d').date()
    except Exception as e:
        logger.warning(f"Failed to parse date {time_str}: {e}")
        return None

def fetch_and_load_endpoint(client: bigquery.Client, endpoint_name: str, config: dict):
    """Fetch data from endpoint and load to BigQuery"""
    logger.info(f"Fetching data from {endpoint_name} endpoint")

    try:
        # Fetch data from API
        response = requests.get(config['url'], timeout=30)
        response.raise_for_status()
        data = response.json()

        if not data or endpoint_name not in data:
            logger.warning(f"No data returned for {endpoint_name}")
            return 0

        records = data[endpoint_name]
        logger.info(f"Fetched {len(records)} records from {endpoint_name}")

        # Transform data
        rows_to_insert = []
        for record in records:
            measurement_date = parse_time_to_date(record.get('time', ''))
            if not measurement_date:
                continue

            row = {
                'record_id': generate_record_id(endpoint_name, record.get('time', '')),
                'measurement_date': measurement_date.isoformat(),
                'ingestion_timestamp': datetime.utcnow().isoformat(),
                'source_file': config['url']
            }

            # Add endpoint-specific fields
            for field in config['fields']:
                if field != 'time':
                    row[field] = record.get(field)

            rows_to_insert.append(row)

        if not rows_to_insert:
            logger.warning(f"No valid records to insert for {endpoint_name}")
            return 0

        # Load to BigQuery using WRITE_TRUNCATE (replace data)
        table_id = f"{PROJECT_ID}.{DATASET_ID}.{config['table']}"

        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            schema_update_options=[
                bigquery.SchemaUpdateOption.ALLOW_FIELD_ADDITION
            ]
        )

        job = client.load_table_from_json(
            rows_to_insert,
            table_id,
            job_config=job_config
        )

        job.result()  # Wait for job to complete

        logger.info(f"Loaded {len(rows_to_insert)} rows to {table_id}")
        return len(rows_to_insert)

    except requests.exceptions.RequestException as e:
        logger.error(f"HTTP request failed for {endpoint_name}: {e}")
        raise
    except Exception as e:
        logger.error(f"Failed to load {endpoint_name}: {e}")
        raise

@functions_framework.http
def ingest_global_warming_data(request):
    """HTTP Cloud Function to ingest Global Warming API data"""

    try:
        client = bigquery.Client(project=PROJECT_ID)

        results = {}
        total_records = 0

        # Process each endpoint
        for endpoint_name, config in API_ENDPOINTS.items():
            try:
                count = fetch_and_load_endpoint(client, endpoint_name, config)
                results[endpoint_name] = {
                    'status': 'success',
                    'records': count
                }
                total_records += count
            except Exception as e:
                results[endpoint_name] = {
                    'status': 'failed',
                    'error': str(e)
                }

        # Return summary
        success_count = sum(1 for r in results.values() if r['status'] == 'success')

        return {
            'status': 'completed',
            'timestamp': datetime.utcnow().isoformat(),
            'total_records': total_records,
            'endpoints_processed': len(API_ENDPOINTS),
            'endpoints_succeeded': success_count,
            'details': results
        }, 200

    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500
```

`requirements.txt`:
```txt
functions-framework==3.*
google-cloud-bigquery==3.*
requests==2.*
```

#### Deployment Instructions

```bash
# Set environment variables
export PROJECT_ID="your-project-id"
export REGION="us-central1"
export FUNCTION_NAME="global-warming-api-ingest"

# Deploy Cloud Function
gcloud functions deploy ${FUNCTION_NAME} \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point ingest_global_warming_data \
  --region ${REGION} \
  --timeout 540s \
  --memory 512MB \
  --set-env-vars PROJECT_ID=${PROJECT_ID}

# Create Cloud Scheduler job (monthly on 5th at 2 AM UTC)
gcloud scheduler jobs create http global-warming-api-monthly \
  --location ${REGION} \
  --schedule "0 2 5 * *" \
  --uri "https://${REGION}-${PROJECT_ID}.cloudfunctions.net/${FUNCTION_NAME}" \
  --http-method POST \
  --time-zone "UTC" \
  --description "Monthly ingestion of Global Warming API data"
```

#### Data Quality Checks

```sql
-- Check data freshness (temperature data)
SELECT
  MAX(measurement_date) as latest_date,
  DATE_DIFF(CURRENT_DATE(), MAX(measurement_date), DAY) as days_since_update,
  COUNT(*) as total_records
FROM climate_data.raw_gw_temperature;

-- Check for duplicate records
SELECT
  record_id,
  COUNT(*) as duplicate_count
FROM climate_data.raw_gw_temperature
GROUP BY record_id
HAVING COUNT(*) > 1;

-- Check for null values in key fields
SELECT
  COUNTIF(land IS NULL) as null_land,
  COUNTIF(station IS NULL) as null_station,
  COUNT(*) as total_records
FROM climate_data.raw_gw_temperature;

-- Validate CO2 trends (should be generally increasing)
SELECT
  measurement_date,
  trend,
  LAG(trend) OVER (ORDER BY measurement_date) as prev_trend,
  trend - LAG(trend) OVER (ORDER BY measurement_date) as trend_change
FROM climate_data.raw_gw_co2
ORDER BY measurement_date DESC
LIMIT 12;
```

#### Monitoring & Alerting

**Cloud Monitoring Alert Policy:**
```yaml
# Create alert for pipeline failures
display_name: "Global Warming API Ingestion Failure"
conditions:
  - display_name: "Function execution failures"
    condition_threshold:
      filter: |
        resource.type = "cloud_function"
        resource.labels.function_name = "global-warming-api-ingest"
        metric.type = "cloudfunctions.googleapis.com/function/execution_count"
        metric.labels.status = "error"
      comparison: COMPARISON_GT
      threshold_value: 0
      duration: 60s
notification_channels:
  - projects/[PROJECT_ID]/notificationChannels/[CHANNEL_ID]
```

---

### Dataset 2: NASA GISTEMP v4 (LOW Complexity)

#### Overview
- **Source:** https://data.giss.nasa.gov/gistemp/
- **Format:** CSV, TXT, NetCDF
- **Update Frequency:** Monthly
- **Authentication:** None
- **Key Files:**
  - `GLB.Ts+dSST.csv` - Global monthly temperature anomalies
  - `ZonAnn.Ts+dSST.csv` - Zonal annual means
  - `NH.Ts+dSST.csv` - Northern Hemisphere
  - `SH.Ts+dSST.csv` - Southern Hemisphere

#### BigQuery Schema Design

```sql
-- Global temperature anomalies (monthly)
CREATE OR REPLACE TABLE climate_data.raw_gistemp_global (
  year INT64 NOT NULL,
  month INT64 NOT NULL,
  temperature_anomaly FLOAT64,
  measurement_date DATE NOT NULL,
  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING,
  hemisphere STRING  -- 'Global', 'Northern', 'Southern'
)
PARTITION BY measurement_date
CLUSTER BY hemisphere, year
OPTIONS(
  description='NASA GISTEMP v4 - Monthly temperature anomalies',
  require_partition_filter=FALSE
);

-- Zonal annual means
CREATE OR REPLACE TABLE climate_data.raw_gistemp_zonal (
  year INT64 NOT NULL,
  zone STRING NOT NULL,  -- 'Glob', 'NHem', 'SHem', '24N-90N', etc.
  temperature_anomaly FLOAT64,
  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
CLUSTER BY zone, year
OPTIONS(
  description='NASA GISTEMP v4 - Zonal annual temperature means'
);
```

#### Data Pipeline Architecture

**Components:**
- **Cloud Scheduler:** Monthly trigger (15th of each month)
- **Cloud Function:** Download CSV files from NASA servers
- **Cloud Storage:** Temporary staging
- **BigQuery:** Load from GCS

**Pipeline Flow:**
```
Cloud Scheduler → Cloud Function → Cloud Storage → BigQuery
                       ↓
                  Cloud Logging
```

#### Implementation Code

**Cloud Function: `nasa_gistemp_ingest`**

`main.py`:
```python
import functions_framework
import requests
from google.cloud import bigquery, storage
from datetime import datetime, date
import hashlib
import csv
import io
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = 'YOUR_PROJECT_ID'
DATASET_ID = 'climate_data'
BUCKET_NAME = 'YOUR_BUCKET_NAME-climate-staging'

# NASA GISTEMP data URLs
DATA_SOURCES = {
    'global': {
        'url': 'https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv',
        'table': 'raw_gistemp_global',
        'hemisphere': 'Global'
    },
    'northern': {
        'url': 'https://data.giss.nasa.gov/gistemp/tabledata_v4/NH.Ts+dSST.csv',
        'table': 'raw_gistemp_global',
        'hemisphere': 'Northern'
    },
    'southern': {
        'url': 'https://data.giss.nasa.gov/gistemp/tabledata_v4/SH.Ts+dSST.csv',
        'table': 'raw_gistemp_global',
        'hemisphere': 'Southern'
    },
    'zonal': {
        'url': 'https://data.giss.nasa.gov/gistemp/tabledata_v4/ZonAnn.Ts+dSST.csv',
        'table': 'raw_gistemp_zonal',
        'type': 'zonal'
    }
}

MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

def generate_record_id(hemisphere: str, year: int, month: int = None) -> str:
    """Generate unique record ID"""
    if month:
        composite = f"gistemp_{hemisphere}_{year}_{month:02d}"
    else:
        composite = f"gistemp_{hemisphere}_{year}"
    return hashlib.md5(composite.encode()).hexdigest()

def parse_gistemp_csv(csv_content: str, source_type: str, hemisphere: str = None) -> list:
    """Parse NASA GISTEMP CSV format"""
    rows = []
    reader = csv.DictReader(io.StringIO(csv_content))

    for row in reader:
        try:
            year = int(row['Year'])

            if source_type == 'zonal':
                # Zonal annual data
                for zone_name, value in row.items():
                    if zone_name == 'Year':
                        continue

                    try:
                        temp_anomaly = float(value)
                        if temp_anomaly == 999.9:  # Missing data indicator
                            continue

                        rows.append({
                            'year': year,
                            'zone': zone_name,
                            'temperature_anomaly': temp_anomaly,
                            'record_id': generate_record_id(zone_name, year),
                            'ingestion_timestamp': datetime.utcnow().isoformat(),
                            'source_file': DATA_SOURCES['zonal']['url']
                        })
                    except (ValueError, TypeError):
                        continue
            else:
                # Monthly data
                for month_idx, month_name in enumerate(MONTH_NAMES, 1):
                    if month_name not in row:
                        continue

                    try:
                        temp_anomaly = float(row[month_name])
                        if temp_anomaly == 999.9:  # Missing data indicator
                            continue

                        measurement_date = date(year, month_idx, 1)

                        rows.append({
                            'year': year,
                            'month': month_idx,
                            'temperature_anomaly': temp_anomaly,
                            'measurement_date': measurement_date.isoformat(),
                            'record_id': generate_record_id(hemisphere, year, month_idx),
                            'ingestion_timestamp': datetime.utcnow().isoformat(),
                            'source_file': DATA_SOURCES[source_type]['url'],
                            'hemisphere': hemisphere
                        })
                    except (ValueError, TypeError):
                        continue

        except (ValueError, KeyError) as e:
            logger.warning(f"Failed to parse row: {e}")
            continue

    return rows

def fetch_and_load_gistemp(client: bigquery.Client, source_name: str, config: dict):
    """Fetch GISTEMP data and load to BigQuery"""
    logger.info(f"Fetching data from {source_name}")

    try:
        # Download CSV
        response = requests.get(config['url'], timeout=30)
        response.raise_for_status()

        # Parse CSV
        source_type = source_name if source_name == 'zonal' else 'monthly'
        hemisphere = config.get('hemisphere')
        rows = parse_gistemp_csv(response.text, source_type, hemisphere)

        logger.info(f"Parsed {len(rows)} records from {source_name}")

        if not rows:
            logger.warning(f"No valid records for {source_name}")
            return 0

        # Load to BigQuery
        table_id = f"{PROJECT_ID}.{DATASET_ID}.{config['table']}"

        # For monthly data, use MERGE to handle updates
        if source_type == 'monthly':
            # Create temporary table
            temp_table_id = f"{table_id}_temp_{int(datetime.utcnow().timestamp())}"

            job_config = bigquery.LoadJobConfig(
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            )

            job = client.load_table_from_json(rows, temp_table_id, job_config=job_config)
            job.result()

            # Merge into main table
            merge_query = f"""
            MERGE `{table_id}` AS target
            USING `{temp_table_id}` AS source
            ON target.record_id = source.record_id
            WHEN MATCHED THEN
              UPDATE SET
                temperature_anomaly = source.temperature_anomaly,
                ingestion_timestamp = source.ingestion_timestamp
            WHEN NOT MATCHED THEN
              INSERT (year, month, temperature_anomaly, measurement_date, record_id,
                      ingestion_timestamp, source_file, hemisphere)
              VALUES (source.year, source.month, source.temperature_anomaly,
                      source.measurement_date, source.record_id,
                      source.ingestion_timestamp, source.source_file, source.hemisphere)
            """

            merge_job = client.query(merge_query)
            merge_job.result()

            # Delete temp table
            client.delete_table(temp_table_id)

        else:
            # For zonal data, truncate and reload
            job_config = bigquery.LoadJobConfig(
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            )

            job = client.load_table_from_json(rows, table_id, job_config=job_config)
            job.result()

        logger.info(f"Loaded {len(rows)} rows to {table_id}")
        return len(rows)

    except Exception as e:
        logger.error(f"Failed to load {source_name}: {e}")
        raise

@functions_framework.http
def ingest_gistemp_data(request):
    """HTTP Cloud Function to ingest NASA GISTEMP data"""

    try:
        client = bigquery.Client(project=PROJECT_ID)

        results = {}
        total_records = 0

        # Process each data source
        for source_name, config in DATA_SOURCES.items():
            try:
                count = fetch_and_load_gistemp(client, source_name, config)
                results[source_name] = {
                    'status': 'success',
                    'records': count
                }
                total_records += count
            except Exception as e:
                results[source_name] = {
                    'status': 'failed',
                    'error': str(e)
                }

        success_count = sum(1 for r in results.values() if r['status'] == 'success')

        return {
            'status': 'completed',
            'timestamp': datetime.utcnow().isoformat(),
            'total_records': total_records,
            'sources_processed': len(DATA_SOURCES),
            'sources_succeeded': success_count,
            'details': results
        }, 200

    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500
```

`requirements.txt`:
```txt
functions-framework==3.*
google-cloud-bigquery==3.*
google-cloud-storage==2.*
requests==2.*
```

#### Deployment Instructions

```bash
# Deploy Cloud Function
gcloud functions deploy nasa-gistemp-ingest \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point ingest_gistemp_data \
  --region us-central1 \
  --timeout 540s \
  --memory 512MB \
  --set-env-vars PROJECT_ID=${PROJECT_ID}

# Create Cloud Scheduler job (monthly on 15th at 3 AM UTC)
gcloud scheduler jobs create http nasa-gistemp-monthly \
  --location us-central1 \
  --schedule "0 3 15 * *" \
  --uri "https://us-central1-${PROJECT_ID}.cloudfunctions.net/nasa-gistemp-ingest" \
  --http-method POST \
  --time-zone "UTC" \
  --description "Monthly ingestion of NASA GISTEMP temperature data"
```

#### Data Quality Checks

```sql
-- Check latest data availability
SELECT
  hemisphere,
  MAX(measurement_date) as latest_month,
  DATE_DIFF(CURRENT_DATE(), MAX(measurement_date), DAY) as days_old,
  COUNT(*) as total_records
FROM climate_data.raw_gistemp_global
GROUP BY hemisphere;

-- Validate temperature anomaly ranges (should be between -5 and +5 typically)
SELECT
  hemisphere,
  MIN(temperature_anomaly) as min_anomaly,
  MAX(temperature_anomaly) as max_anomaly,
  AVG(temperature_anomaly) as avg_anomaly,
  STDDEV(temperature_anomaly) as stddev_anomaly
FROM climate_data.raw_gistemp_global
GROUP BY hemisphere;

-- Check for missing months in time series
WITH month_series AS (
  SELECT
    DATE_TRUNC(DATE_ADD('1880-01-01', INTERVAL n MONTH), MONTH) as expected_month
  FROM UNNEST(GENERATE_ARRAY(0, 1800)) as n  -- ~150 years
)
SELECT
  ms.expected_month,
  g.measurement_date,
  g.hemisphere
FROM month_series ms
LEFT JOIN climate_data.raw_gistemp_global g
  ON ms.expected_month = g.measurement_date
  AND g.hemisphere = 'Global'
WHERE g.measurement_date IS NULL
  AND ms.expected_month <= CURRENT_DATE()
ORDER BY ms.expected_month DESC
LIMIT 20;
```

---

### Dataset 3: Our World in Data - CO2 Emissions (LOW Complexity)

#### Overview
- **Source:** https://github.com/owid/co2-data
- **Format:** CSV
- **Update Frequency:** Annually (usually Q1)
- **Authentication:** None
- **Direct CSV:** https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.csv

#### BigQuery Schema Design

```sql
-- CO2 and greenhouse gas emissions by country
CREATE OR REPLACE TABLE climate_data.raw_owid_co2 (
  iso_code STRING,
  country STRING NOT NULL,
  year INT64 NOT NULL,

  -- CO2 emissions
  co2 FLOAT64,  -- Annual CO2 emissions (million tonnes)
  co2_per_capita FLOAT64,
  co2_per_gdp FLOAT64,
  cumulative_co2 FLOAT64,

  -- CO2 by source
  coal_co2 FLOAT64,
  gas_co2 FLOAT64,
  oil_co2 FLOAT64,
  cement_co2 FLOAT64,
  flaring_co2 FLOAT64,
  other_industry_co2 FLOAT64,

  -- Other greenhouse gases
  methane FLOAT64,
  nitrous_oxide FLOAT64,
  total_ghg FLOAT64,

  -- Context
  population FLOAT64,
  gdp FLOAT64,

  -- Metadata
  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY RANGE_BUCKET(year, GENERATE_ARRAY(1750, 2100, 1))
CLUSTER BY country, iso_code
OPTIONS(
  description='Our World in Data - CO2 and greenhouse gas emissions by country',
  require_partition_filter=FALSE
);
```

#### Data Pipeline Architecture

**Components:**
- **Cloud Scheduler:** Annual trigger (March 1st)
- **Cloud Function:** Download CSV and load to BigQuery
- **BigQuery:** Direct load from CSV

#### Implementation Code

**Cloud Function: `owid_co2_ingest`**

`main.py`:
```python
import functions_framework
import requests
from google.cloud import bigquery
from datetime import datetime
import hashlib
import csv
import io
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = 'YOUR_PROJECT_ID'
DATASET_ID = 'climate_data'
TABLE_ID = 'raw_owid_co2'

OWID_CO2_URL = 'https://nyc3.digitaloceanspaces.com/owid-public/data/co2/owid-co2-data.csv'

# Fields to extract from OWID CSV
FIELDS_TO_EXTRACT = [
    'iso_code', 'country', 'year',
    'co2', 'co2_per_capita', 'co2_per_gdp', 'cumulative_co2',
    'coal_co2', 'gas_co2', 'oil_co2', 'cement_co2', 'flaring_co2', 'other_industry_co2',
    'methane', 'nitrous_oxide', 'total_ghg',
    'population', 'gdp'
]

def generate_record_id(country: str, year: int) -> str:
    """Generate unique record ID"""
    composite = f"owid_co2_{country}_{year}"
    return hashlib.md5(composite.encode()).hexdigest()

def safe_float(value: str) -> float:
    """Convert string to float, return None if empty or invalid"""
    if not value or value.strip() == '':
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None

def safe_int(value: str) -> int:
    """Convert string to int, return None if empty or invalid"""
    if not value or value.strip() == '':
        return None
    try:
        return int(value)
    except (ValueError, TypeError):
        return None

def parse_owid_csv(csv_content: str) -> list:
    """Parse OWID CO2 CSV"""
    rows = []
    reader = csv.DictReader(io.StringIO(csv_content))

    for row in reader:
        try:
            country = row.get('country', '').strip()
            year = safe_int(row.get('year'))

            if not country or not year:
                continue

            record = {
                'iso_code': row.get('iso_code', '').strip() or None,
                'country': country,
                'year': year,
                'co2': safe_float(row.get('co2')),
                'co2_per_capita': safe_float(row.get('co2_per_capita')),
                'co2_per_gdp': safe_float(row.get('co2_per_gdp')),
                'cumulative_co2': safe_float(row.get('cumulative_co2')),
                'coal_co2': safe_float(row.get('coal_co2')),
                'gas_co2': safe_float(row.get('gas_co2')),
                'oil_co2': safe_float(row.get('oil_co2')),
                'cement_co2': safe_float(row.get('cement_co2')),
                'flaring_co2': safe_float(row.get('flaring_co2')),
                'other_industry_co2': safe_float(row.get('other_industry_co2')),
                'methane': safe_float(row.get('methane')),
                'nitrous_oxide': safe_float(row.get('nitrous_oxide')),
                'total_ghg': safe_float(row.get('total_ghg')),
                'population': safe_float(row.get('population')),
                'gdp': safe_float(row.get('gdp')),
                'record_id': generate_record_id(country, year),
                'ingestion_timestamp': datetime.utcnow().isoformat(),
                'source_file': OWID_CO2_URL
            }

            rows.append(record)

        except Exception as e:
            logger.warning(f"Failed to parse row: {e}")
            continue

    return rows

@functions_framework.http
def ingest_owid_co2_data(request):
    """HTTP Cloud Function to ingest OWID CO2 data"""

    try:
        logger.info(f"Downloading OWID CO2 data from {OWID_CO2_URL}")

        # Download CSV
        response = requests.get(OWID_CO2_URL, timeout=120)
        response.raise_for_status()

        logger.info(f"Downloaded {len(response.text)} bytes")

        # Parse CSV
        rows = parse_owid_csv(response.text)
        logger.info(f"Parsed {len(rows)} records")

        if not rows:
            return {
                'status': 'failed',
                'error': 'No valid records parsed',
                'timestamp': datetime.utcnow().isoformat()
            }, 400

        # Load to BigQuery
        client = bigquery.Client(project=PROJECT_ID)
        table_id = f"{PROJECT_ID}.{DATASET_ID}.{TABLE_ID}"

        # Use WRITE_TRUNCATE to replace all data (annual full refresh)
        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )

        job = client.load_table_from_json(rows, table_id, job_config=job_config)
        job.result()  # Wait for completion

        logger.info(f"Successfully loaded {len(rows)} rows to {table_id}")

        # Get table stats
        table = client.get_table(table_id)

        return {
            'status': 'success',
            'timestamp': datetime.utcnow().isoformat(),
            'records_loaded': len(rows),
            'table_rows': table.num_rows,
            'table_size_mb': table.num_bytes / (1024 * 1024),
            'source_url': OWID_CO2_URL
        }, 200

    except requests.exceptions.RequestException as e:
        logger.error(f"HTTP request failed: {e}")
        return {
            'status': 'failed',
            'error': f'HTTP error: {str(e)}',
            'timestamp': datetime.utcnow().isoformat()
        }, 500
    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500
```

`requirements.txt`:
```txt
functions-framework==3.*
google-cloud-bigquery==3.*
requests==2.*
```

#### Deployment Instructions

```bash
# Deploy Cloud Function
gcloud functions deploy owid-co2-ingest \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point ingest_owid_co2_data \
  --region us-central1 \
  --timeout 540s \
  --memory 1024MB \
  --set-env-vars PROJECT_ID=${PROJECT_ID}

# Create Cloud Scheduler job (annually on March 1st at 4 AM UTC)
gcloud scheduler jobs create http owid-co2-annual \
  --location us-central1 \
  --schedule "0 4 1 3 *" \
  --uri "https://us-central1-${PROJECT_ID}.cloudfunctions.net/owid-co2-ingest" \
  --http-method POST \
  --time-zone "UTC" \
  --description "Annual ingestion of OWID CO2 emissions data"

# Also create a monthly check (in case of data updates)
gcloud scheduler jobs create http owid-co2-monthly-check \
  --location us-central1 \
  --schedule "0 4 1 * *" \
  --uri "https://us-central1-${PROJECT_ID}.cloudfunctions.net/owid-co2-ingest" \
  --http-method POST \
  --time-zone "UTC" \
  --description "Monthly check for OWID CO2 data updates"
```

#### Data Quality Checks

```sql
-- Check latest year available by country
SELECT
  country,
  MAX(year) as latest_year,
  COUNT(*) as total_years
FROM climate_data.raw_owid_co2
WHERE iso_code IS NOT NULL  -- Exclude aggregates
GROUP BY country
HAVING MAX(year) < EXTRACT(YEAR FROM CURRENT_DATE()) - 2
ORDER BY country;

-- Check top CO2 emitters (latest year)
WITH latest_year AS (
  SELECT MAX(year) as max_year
  FROM climate_data.raw_owid_co2
)
SELECT
  country,
  year,
  co2,
  co2_per_capita,
  RANK() OVER (ORDER BY co2 DESC) as rank_total,
  RANK() OVER (ORDER BY co2_per_capita DESC) as rank_per_capita
FROM climate_data.raw_owid_co2
WHERE year = (SELECT max_year FROM latest_year)
  AND iso_code IS NOT NULL
  AND co2 IS NOT NULL
ORDER BY co2 DESC
LIMIT 20;

-- Validate data completeness for major countries
SELECT
  country,
  COUNT(*) as years_with_data,
  MIN(year) as first_year,
  MAX(year) as last_year,
  COUNTIF(co2 IS NULL) as missing_co2,
  COUNTIF(population IS NULL) as missing_population
FROM climate_data.raw_owid_co2
WHERE country IN ('United States', 'China', 'India', 'Germany', 'United Kingdom', 'Japan')
GROUP BY country
ORDER BY country;

-- Check for anomalies (negative emissions)
SELECT
  country,
  year,
  co2,
  coal_co2,
  gas_co2,
  oil_co2
FROM climate_data.raw_owid_co2
WHERE co2 < 0
  OR coal_co2 < 0
  OR gas_co2 < 0
  OR oil_co2 < 0
ORDER BY year DESC;
```

---

### Dataset 4: NOAA Climate Data Online (CDO) API (MEDIUM Complexity)

#### Overview
- **Source:** https://www.ncdc.noaa.gov/cdo-web/api/v2/
- **Format:** JSON (REST API)
- **Update Frequency:** Daily
- **Authentication:** Free API token required
- **Rate Limits:** 5 requests/second, 10,000 requests/day
- **Key Endpoints:**
  - `/datasets` - List available datasets
  - `/stations` - Weather station metadata
  - `/data` - Actual observations

#### BigQuery Schema Design

```sql
-- Weather station metadata
CREATE OR REPLACE TABLE climate_data.raw_noaa_stations (
  station_id STRING NOT NULL,
  name STRING,
  latitude FLOAT64,
  longitude FLOAT64,
  elevation FLOAT64,
  min_date DATE,
  max_date DATE,
  datacoverage FLOAT64,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
CLUSTER BY station_id
OPTIONS(
  description='NOAA weather station metadata'
);

-- Daily weather observations
CREATE OR REPLACE TABLE climate_data.raw_noaa_daily_observations (
  station_id STRING NOT NULL,
  observation_date DATE NOT NULL,
  datatype STRING NOT NULL,  -- TMAX, TMIN, PRCP, SNOW, etc.
  value FLOAT64,
  attributes STRING,
  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY observation_date
CLUSTER BY station_id, datatype
OPTIONS(
  description='NOAA daily weather observations',
  require_partition_filter=TRUE,
  partition_expiration_days=NULL
);

-- Wide format for analytical queries
CREATE OR REPLACE TABLE climate_data.raw_noaa_daily_wide (
  station_id STRING NOT NULL,
  observation_date DATE NOT NULL,
  station_name STRING,
  latitude FLOAT64,
  longitude FLOAT64,

  -- Temperature (tenths of degrees C)
  tmax FLOAT64,  -- Maximum temperature
  tmin FLOAT64,  -- Minimum temperature
  tavg FLOAT64,  -- Average temperature

  -- Precipitation (tenths of mm)
  prcp FLOAT64,  -- Precipitation
  snow FLOAT64,  -- Snowfall
  snwd FLOAT64,  -- Snow depth

  -- Wind
  awnd FLOAT64,  -- Average wind speed

  -- Other
  pressure FLOAT64,

  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP()
)
PARTITION BY observation_date
CLUSTER BY station_id
OPTIONS(
  description='NOAA daily observations in wide format',
  require_partition_filter=TRUE
);
```

#### Authentication Setup

```bash
# Store NOAA API token in Secret Manager
export NOAA_API_TOKEN="your-token-here"

gcloud secrets create noaa-cdo-api-token \
  --data-file=- <<< "${NOAA_API_TOKEN}" \
  --replication-policy="automatic"

# Grant Cloud Function access to secret
gcloud secrets add-iam-policy-binding noaa-cdo-api-token \
  --member="serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

#### Implementation Code

**Cloud Function: `noaa_cdo_ingest`**

`main.py`:
```python
import functions_framework
import requests
from google.cloud import bigquery, secretmanager
from datetime import datetime, date, timedelta
import hashlib
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = 'YOUR_PROJECT_ID'
DATASET_ID = 'climate_data'

NOAA_API_BASE = 'https://www.ncdc.noaa.gov/cdo-web/api/v2'
RATE_LIMIT_DELAY = 0.21  # 5 requests/second = 0.2s delay, add buffer

# Focus on key datatypes
DATATYPES = ['TMAX', 'TMIN', 'TAVG', 'PRCP', 'SNOW', 'SNWD', 'AWND']

# Major US stations for initial implementation
STATION_IDS = [
    'GHCND:USW00094728',  # New York Central Park
    'GHCND:USW00023174',  # Los Angeles
    'GHCND:USW00094846',  # Chicago O'Hare
    'GHCND:USW00012960',  # Houston
    'GHCND:USW00023234',  # Phoenix
    'GHCND:USW00013874',  # Miami
]

def get_api_token() -> str:
    """Retrieve API token from Secret Manager"""
    client = secretmanager.SecretManagerServiceClient()
    secret_name = f"projects/{PROJECT_ID}/secrets/noaa-cdo-api-token/versions/latest"
    response = client.access_secret_version(request={"name": secret_name})
    return response.payload.data.decode('UTF-8')

def generate_record_id(station_id: str, obs_date: str, datatype: str) -> str:
    """Generate unique record ID"""
    composite = f"noaa_{station_id}_{obs_date}_{datatype}"
    return hashlib.md5(composite.encode()).hexdigest()

def fetch_noaa_data(api_token: str, dataset_id: str, start_date: str,
                     end_date: str, station_id: str, datatype: str) -> list:
    """Fetch data from NOAA CDO API with rate limiting"""

    headers = {'token': api_token}
    params = {
        'datasetid': dataset_id,
        'stationid': station_id,
        'datatypeid': datatype,
        'startdate': start_date,
        'enddate': end_date,
        'limit': 1000,  # Max per request
        'units': 'metric'
    }

    all_results = []
    offset = 1

    while True:
        params['offset'] = offset

        try:
            time.sleep(RATE_LIMIT_DELAY)  # Rate limiting

            response = requests.get(
                f'{NOAA_API_BASE}/data',
                headers=headers,
                params=params,
                timeout=30
            )
            response.raise_for_status()

            data = response.json()

            if 'results' not in data or not data['results']:
                break

            all_results.extend(data['results'])

            # Check if there are more pages
            metadata = data.get('metadata', {})
            result_set = metadata.get('resultset', {})

            if offset >= result_set.get('count', 0):
                break

            offset += len(data['results'])

            logger.info(f"Fetched {len(all_results)} records so far for {datatype}")

        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {e}")
            raise

    return all_results

def transform_noaa_observations(observations: list) -> list:
    """Transform NOAA observations to BigQuery schema"""
    rows = []

    for obs in observations:
        try:
            obs_date = obs['date'].split('T')[0]  # Extract date from timestamp

            row = {
                'station_id': obs['station'],
                'observation_date': obs_date,
                'datatype': obs['datatype'],
                'value': obs['value'],
                'attributes': obs.get('attributes', ''),
                'record_id': generate_record_id(obs['station'], obs_date, obs['datatype']),
                'ingestion_timestamp': datetime.utcnow().isoformat()
            }

            rows.append(row)

        except (KeyError, ValueError) as e:
            logger.warning(f"Failed to transform observation: {e}")
            continue

    return rows

@functions_framework.http
def ingest_noaa_daily_data(request):
    """HTTP Cloud Function to ingest NOAA daily observations"""

    try:
        # Parse request parameters
        request_json = request.get_json(silent=True)

        if request_json and 'date' in request_json:
            target_date = datetime.strptime(request_json['date'], '%Y-%m-%d').date()
        else:
            # Default to yesterday
            target_date = date.today() - timedelta(days=1)

        start_date = target_date.isoformat()
        end_date = target_date.isoformat()

        logger.info(f"Ingesting NOAA data for {target_date}")

        # Get API token
        api_token = get_api_token()

        # Initialize BigQuery client
        client = bigquery.Client(project=PROJECT_ID)

        all_observations = []

        # Fetch data for each station and datatype
        for station_id in STATION_IDS:
            for datatype in DATATYPES:
                try:
                    logger.info(f"Fetching {datatype} for {station_id}")

                    observations = fetch_noaa_data(
                        api_token=api_token,
                        dataset_id='GHCND',  # Global Historical Climatology Network Daily
                        start_date=start_date,
                        end_date=end_date,
                        station_id=station_id,
                        datatype=datatype
                    )

                    all_observations.extend(observations)

                except Exception as e:
                    logger.error(f"Failed to fetch {datatype} for {station_id}: {e}")
                    continue

        logger.info(f"Total observations fetched: {len(all_observations)}")

        if not all_observations:
            return {
                'status': 'completed',
                'message': 'No observations available for this date',
                'date': target_date.isoformat(),
                'timestamp': datetime.utcnow().isoformat()
            }, 200

        # Transform observations
        rows = transform_noaa_observations(all_observations)

        # Load to BigQuery
        table_id = f"{PROJECT_ID}.{DATASET_ID}.raw_noaa_daily_observations"

        # Use MERGE to handle duplicates
        temp_table_id = f"{table_id}_temp_{int(datetime.utcnow().timestamp())}"

        job_config = bigquery.LoadJobConfig(
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )

        job = client.load_table_from_json(rows, temp_table_id, job_config=job_config)
        job.result()

        # Merge into main table
        merge_query = f"""
        MERGE `{table_id}` AS target
        USING `{temp_table_id}` AS source
        ON target.record_id = source.record_id
        WHEN MATCHED THEN
          UPDATE SET
            value = source.value,
            attributes = source.attributes,
            ingestion_timestamp = source.ingestion_timestamp
        WHEN NOT MATCHED THEN
          INSERT (station_id, observation_date, datatype, value, attributes, record_id, ingestion_timestamp)
          VALUES (source.station_id, source.observation_date, source.datatype, source.value,
                  source.attributes, source.record_id, source.ingestion_timestamp)
        """

        merge_job = client.query(merge_query)
        result = merge_job.result()

        # Delete temp table
        client.delete_table(temp_table_id)

        logger.info(f"Successfully loaded {len(rows)} observations")

        return {
            'status': 'success',
            'date': target_date.isoformat(),
            'timestamp': datetime.utcnow().isoformat(),
            'observations_loaded': len(rows),
            'stations_processed': len(STATION_IDS),
            'datatypes_processed': len(DATATYPES)
        }, 200

    except Exception as e:
        logger.error(f"Pipeline failed: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500
```

`requirements.txt`:
```txt
functions-framework==3.*
google-cloud-bigquery==3.*
google-cloud-secret-manager==2.*
requests==2.*
```

#### Deployment Instructions

```bash
# Deploy Cloud Function with Secret Manager access
gcloud functions deploy noaa-cdo-ingest \
  --runtime python311 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point ingest_noaa_daily_data \
  --region us-central1 \
  --timeout 540s \
  --memory 512MB \
  --set-env-vars PROJECT_ID=${PROJECT_ID} \
  --service-account ${PROJECT_ID}@appspot.gserviceaccount.com

# Create Cloud Scheduler job (daily at 6 AM UTC, after NOAA updates)
gcloud scheduler jobs create http noaa-cdo-daily \
  --location us-central1 \
  --schedule "0 6 * * *" \
  --uri "https://us-central1-${PROJECT_ID}.cloudfunctions.net/noaa-cdo-ingest" \
  --http-method POST \
  --time-zone "UTC" \
  --description "Daily ingestion of NOAA weather observations"
```

#### Create Wide Format View

```sql
-- Create wide format table for easier analysis
CREATE OR REPLACE TABLE climate_data.raw_noaa_daily_wide
PARTITION BY observation_date
CLUSTER BY station_id
AS
WITH pivoted AS (
  SELECT
    station_id,
    observation_date,
    MAX(IF(datatype = 'TMAX', value, NULL)) as tmax,
    MAX(IF(datatype = 'TMIN', value, NULL)) as tmin,
    MAX(IF(datatype = 'TAVG', value, NULL)) as tavg,
    MAX(IF(datatype = 'PRCP', value, NULL)) as prcp,
    MAX(IF(datatype = 'SNOW', value, NULL)) as snow,
    MAX(IF(datatype = 'SNWD', value, NULL)) as snwd,
    MAX(IF(datatype = 'AWND', value, NULL)) as awnd,
    GENERATE_UUID() as record_id,
    CURRENT_TIMESTAMP() as ingestion_timestamp
  FROM climate_data.raw_noaa_daily_observations
  GROUP BY station_id, observation_date
)
SELECT
  p.*,
  s.name as station_name,
  s.latitude,
  s.longitude
FROM pivoted p
LEFT JOIN climate_data.raw_noaa_stations s
  ON p.station_id = s.station_id;
```

#### Data Quality Checks

```sql
-- Check latest data by station
SELECT
  station_id,
  MAX(observation_date) as latest_date,
  DATE_DIFF(CURRENT_DATE(), MAX(observation_date), DAY) as days_old,
  COUNT(DISTINCT observation_date) as total_days,
  COUNT(DISTINCT datatype) as datatypes_count
FROM climate_data.raw_noaa_daily_observations
GROUP BY station_id
ORDER BY latest_date DESC;

-- Check data completeness (all datatypes present)
WITH daily_completeness AS (
  SELECT
    observation_date,
    station_id,
    COUNT(DISTINCT datatype) as datatypes_present
  FROM climate_data.raw_noaa_daily_observations
  WHERE observation_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  GROUP BY observation_date, station_id
)
SELECT
  observation_date,
  AVG(datatypes_present) as avg_datatypes,
  MIN(datatypes_present) as min_datatypes,
  MAX(datatypes_present) as max_datatypes
FROM daily_completeness
GROUP BY observation_date
ORDER BY observation_date DESC;

-- Validate temperature ranges
SELECT
  station_id,
  observation_date,
  datatype,
  value
FROM climate_data.raw_noaa_daily_observations
WHERE datatype IN ('TMAX', 'TMIN')
  AND (value < -500 OR value > 500)  -- Extreme values (in tenths of degrees C)
  AND observation_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
ORDER BY observation_date DESC;
```

---

### Dataset 5: Copernicus ERA5 Reanalysis (HIGH Complexity)

#### Overview
- **Source:** https://cds.climate.copernicus.eu/
- **Format:** NetCDF, GRIB
- **Update Frequency:** Daily (5-day lag)
- **Authentication:** CDS account + API key required
- **Access Method:** Python `cdsapi` client
- **Variables:** 2m temperature, precipitation, wind, pressure, humidity, radiation

#### BigQuery Schema Design

```sql
-- ERA5 hourly reanalysis data
CREATE OR REPLACE TABLE climate_data.raw_era5_hourly (
  measurement_timestamp TIMESTAMP NOT NULL,
  measurement_date DATE NOT NULL,
  latitude FLOAT64 NOT NULL,
  longitude FLOAT64 NOT NULL,

  -- Temperature
  temperature_2m FLOAT64,  -- Kelvin
  temperature_2m_celsius FLOAT64,  -- Celsius (computed)

  -- Precipitation
  total_precipitation FLOAT64,  -- meters

  -- Wind
  u_component_10m FLOAT64,  -- m/s
  v_component_10m FLOAT64,  -- m/s
  wind_speed_10m FLOAT64,  -- m/s (computed)

  -- Pressure
  surface_pressure FLOAT64,  -- Pa

  -- Other
  total_cloud_cover FLOAT64,  -- 0-1

  -- Metadata
  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY measurement_date
CLUSTER BY latitude, longitude
OPTIONS(
  description='ERA5 hourly reanalysis data',
  require_partition_filter=TRUE,
  partition_expiration_days=NULL
);

-- ERA5 daily aggregates
CREATE OR REPLACE TABLE climate_data.raw_era5_daily (
  measurement_date DATE NOT NULL,
  latitude FLOAT64 NOT NULL,
  longitude FLOAT64 NOT NULL,

  -- Temperature statistics
  avg_temperature_2m FLOAT64,
  min_temperature_2m FLOAT64,
  max_temperature_2m FLOAT64,

  -- Precipitation total
  total_precipitation FLOAT64,

  -- Wind statistics
  avg_wind_speed_10m FLOAT64,
  max_wind_speed_10m FLOAT64,

  -- Pressure statistics
  avg_surface_pressure FLOAT64,

  record_id STRING NOT NULL,
  ingestion_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  source_file STRING
)
PARTITION BY measurement_date
CLUSTER BY latitude, longitude
OPTIONS(
  description='ERA5 daily aggregated reanalysis data',
  require_partition_filter=TRUE
);
```

#### Authentication Setup

```bash
# Store CDS API credentials in Secret Manager
export CDS_UID="your-uid"
export CDS_API_KEY="your-api-key"

# Create secret for CDS URL
gcloud secrets create cds-api-url \
  --data-file=- <<< "https://cds.climate.copernicus.eu/api/v2" \
  --replication-policy="automatic"

# Create secret for CDS API key
cat > /tmp/cdsapirc <<EOF
url: https://cds.climate.copernicus.eu/api/v2
key: ${CDS_UID}:${CDS_API_KEY}
EOF

gcloud secrets create cds-api-credentials \
  --data-file=/tmp/cdsapirc \
  --replication-policy="automatic"

rm /tmp/cdsapirc

# Grant access
gcloud secrets add-iam-policy-binding cds-api-credentials \
  --member="serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

#### Data Pipeline Architecture

**Components:**
- **Cloud Scheduler:** Daily trigger
- **Cloud Run:** Long-running NetCDF processing (Cloud Functions timeout too short)
- **Cloud Storage:** Stage NetCDF files
- **Dataflow (optional):** Process large NetCDF files in parallel
- **BigQuery:** Target warehouse

**Pipeline Flow:**
```
Cloud Scheduler → Cloud Run → Cloud Storage (NetCDF) → Dataflow → BigQuery
                       ↓                                   ↓
                  Cloud Logging                    Cloud Monitoring
```

#### Implementation Code

**Cloud Run Service: `era5_ingest`**

`Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for NetCDF
RUN apt-get update && apt-get install -y \
    libnetcdf-dev \
    libhdf5-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY main.py .

# Run the web service
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 3600 main:app
```

`requirements.txt`:
```txt
flask==3.*
gunicorn==21.*
google-cloud-bigquery==3.*
google-cloud-storage==2.*
google-cloud-secret-manager==2.*
cdsapi==0.6.*
netCDF4==1.*
numpy==1.*
xarray==2023.*
```

`main.py`:
```python
import os
import cdsapi
import xarray as xr
import numpy as np
from flask import Flask, request, jsonify
from google.cloud import bigquery, storage, secretmanager
from datetime import datetime, date, timedelta
import hashlib
import logging
import tempfile

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

PROJECT_ID = os.environ.get('PROJECT_ID')
DATASET_ID = 'climate_data'
BUCKET_NAME = os.environ.get('BUCKET_NAME', f'{PROJECT_ID}-climate-staging')

# Define area of interest (can be customized)
# Format: [North, West, South, East]
AREA_OF_INTEREST = [90, -180, -90, 180]  # Global
# AREA_OF_INTEREST = [50, -130, 24, -65]  # USA only

# Variables to download
ERA5_VARIABLES = [
    '2m_temperature',
    'total_precipitation',
    '10m_u_component_of_wind',
    '10m_v_component_of_wind',
    'surface_pressure',
    'total_cloud_cover'
]

def get_cds_credentials():
    """Retrieve CDS API credentials from Secret Manager"""
    client = secretmanager.SecretManagerServiceClient()
    secret_name = f"projects/{PROJECT_ID}/secrets/cds-api-credentials/versions/latest"
    response = client.access_secret_version(request={"name": secret_name})

    # Parse credentials
    creds = response.payload.data.decode('UTF-8')
    lines = creds.strip().split('\n')
    url = lines[0].split(': ')[1]
    key = lines[1].split(': ')[1]

    return url, key

def generate_record_id(timestamp: datetime, lat: float, lon: float) -> str:
    """Generate unique record ID"""
    composite = f"era5_{timestamp.isoformat()}_{lat}_{lon}"
    return hashlib.md5(composite.encode()).hexdigest()

def download_era5_data(target_date: date, output_file: str):
    """Download ERA5 data using CDS API"""
    logger.info(f"Downloading ERA5 data for {target_date}")

    # Get credentials
    url, key = get_cds_credentials()

    # Initialize CDS API client
    c = cdsapi.Client(url=url, key=key)

    # Download request
    c.retrieve(
        'reanalysis-era5-single-levels',
        {
            'product_type': 'reanalysis',
            'variable': ERA5_VARIABLES,
            'year': str(target_date.year),
            'month': f'{target_date.month:02d}',
            'day': f'{target_date.day:02d}',
            'time': [f'{h:02d}:00' for h in range(24)],  # All 24 hours
            'area': AREA_OF_INTEREST,
            'format': 'netcdf',
        },
        output_file
    )

    logger.info(f"Downloaded ERA5 data to {output_file}")

def process_netcdf_to_bigquery(netcdf_file: str, target_date: date) -> int:
    """Process NetCDF file and load to BigQuery"""
    logger.info(f"Processing NetCDF file: {netcdf_file}")

    # Open NetCDF file with xarray
    ds = xr.open_dataset(netcdf_file)

    rows = []

    # Iterate through coordinates
    for time_idx, time_val in enumerate(ds.time.values):
        timestamp = datetime.utcfromtimestamp(time_val.astype('datetime64[s]').astype(int))

        # Sample spatial coordinates (every N degrees to reduce volume)
        # For full resolution, remove [::5, ::5] slicing
        for lat_idx, lat in enumerate(ds.latitude.values[::5]):
            for lon_idx, lon in enumerate(ds.longitude.values[::5]):

                # Extract values
                t2m = float(ds['t2m'][time_idx, lat_idx*5, lon_idx*5].values)
                tp = float(ds['tp'][time_idx, lat_idx*5, lon_idx*5].values)
                u10 = float(ds['u10'][time_idx, lat_idx*5, lon_idx*5].values)
                v10 = float(ds['v10'][time_idx, lat_idx*5, lon_idx*5].values)
                sp = float(ds['sp'][time_idx, lat_idx*5, lon_idx*5].values)
                tcc = float(ds['tcc'][time_idx, lat_idx*5, lon_idx*5].values)

                # Compute derived values
                t2m_celsius = t2m - 273.15  # Kelvin to Celsius
                wind_speed = np.sqrt(u10**2 + v10**2)

                row = {
                    'measurement_timestamp': timestamp.isoformat(),
                    'measurement_date': target_date.isoformat(),
                    'latitude': float(lat),
                    'longitude': float(lon),
                    'temperature_2m': t2m,
                    'temperature_2m_celsius': t2m_celsius,
                    'total_precipitation': tp,
                    'u_component_10m': u10,
                    'v_component_10m': v10,
                    'wind_speed_10m': wind_speed,
                    'surface_pressure': sp,
                    'total_cloud_cover': tcc,
                    'record_id': generate_record_id(timestamp, float(lat), float(lon)),
                    'ingestion_timestamp': datetime.utcnow().isoformat(),
                    'source_file': netcdf_file
                }

                rows.append(row)

    ds.close()

    logger.info(f"Extracted {len(rows)} records from NetCDF")

    # Load to BigQuery
    client = bigquery.Client(project=PROJECT_ID)
    table_id = f"{PROJECT_ID}.{DATASET_ID}.raw_era5_hourly"

    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
    )

    # Load in chunks to avoid memory issues
    chunk_size = 10000
    total_loaded = 0

    for i in range(0, len(rows), chunk_size):
        chunk = rows[i:i + chunk_size]
        job = client.load_table_from_json(chunk, table_id, job_config=job_config)
        job.result()
        total_loaded += len(chunk)
        logger.info(f"Loaded {total_loaded}/{len(rows)} records")

    return len(rows)

@app.route('/ingest', methods=['POST'])
def ingest_era5_data():
    """HTTP endpoint to ingest ERA5 data"""

    try:
        # Parse request
        request_json = request.get_json(silent=True)

        if request_json and 'date' in request_json:
            target_date = datetime.strptime(request_json['date'], '%Y-%m-%d').date()
        else:
            # Default to 5 days ago (ERA5 has 5-day lag)
            target_date = date.today() - timedelta(days=5)

        logger.info(f"Processing ERA5 data for {target_date}")

        # Create temporary file for NetCDF
        with tempfile.NamedTemporaryFile(suffix='.nc', delete=False) as tmp:
            netcdf_file = tmp.name

        try:
            # Download ERA5 data
            download_era5_data(target_date, netcdf_file)

            # Upload to GCS for archival
            storage_client = storage.Client()
            bucket = storage_client.bucket(BUCKET_NAME)
            gcs_path = f"era5/netcdf/{target_date.year}/{target_date.month:02d}/{target_date.isoformat()}.nc"
            blob = bucket.blob(gcs_path)
            blob.upload_from_filename(netcdf_file)
            logger.info(f"Uploaded NetCDF to gs://{BUCKET_NAME}/{gcs_path}")

            # Process and load to BigQuery
            records_loaded = process_netcdf_to_bigquery(netcdf_file, target_date)

            return jsonify({
                'status': 'success',
                'date': target_date.isoformat(),
                'timestamp': datetime.utcnow().isoformat(),
                'records_loaded': records_loaded,
                'netcdf_location': f"gs://{BUCKET_NAME}/{gcs_path}"
            }), 200

        finally:
            # Cleanup temp file
            if os.path.exists(netcdf_file):
                os.remove(netcdf_file)

    except Exception as e:
        logger.error(f"Pipeline failed: {e}", exc_info=True)
        return jsonify({
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
```

#### Deployment Instructions

```bash
# Build and deploy Cloud Run service
export REGION="us-central1"
export SERVICE_NAME="era5-ingest"

# Build container
gcloud builds submit --tag gcr.io/${PROJECT_ID}/${SERVICE_NAME}

# Deploy to Cloud Run
gcloud run deploy ${SERVICE_NAME} \
  --image gcr.io/${PROJECT_ID}/${SERVICE_NAME} \
  --platform managed \
  --region ${REGION} \
  --memory 4Gi \
  --cpu 2 \
  --timeout 3600 \
  --no-allow-unauthenticated \
  --set-env-vars PROJECT_ID=${PROJECT_ID},BUCKET_NAME=${PROJECT_ID}-climate-staging \
  --service-account ${PROJECT_ID}@appspot.gserviceaccount.com

# Get service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format 'value(status.url)')

# Create Cloud Scheduler job (daily at 8 AM UTC for 5 days ago)
gcloud scheduler jobs create http era5-daily \
  --location ${REGION} \
  --schedule "0 8 * * *" \
  --uri "${SERVICE_URL}/ingest" \
  --http-method POST \
  --oidc-service-account-email ${PROJECT_ID}@appspot.gserviceaccount.com \
  --time-zone "UTC" \
  --description "Daily ingestion of ERA5 reanalysis data"
```

#### Create Daily Aggregates

```sql
-- Scheduled query to create daily aggregates from hourly data
CREATE OR REPLACE TABLE climate_data.raw_era5_daily
PARTITION BY measurement_date
CLUSTER BY latitude, longitude
AS
SELECT
  measurement_date,
  latitude,
  longitude,
  AVG(temperature_2m_celsius) as avg_temperature_2m,
  MIN(temperature_2m_celsius) as min_temperature_2m,
  MAX(temperature_2m_celsius) as max_temperature_2m,
  SUM(total_precipitation) as total_precipitation,
  AVG(wind_speed_10m) as avg_wind_speed_10m,
  MAX(wind_speed_10m) as max_wind_speed_10m,
  AVG(surface_pressure) as avg_surface_pressure,
  GENERATE_UUID() as record_id,
  CURRENT_TIMESTAMP() as ingestion_timestamp,
  'aggregated_from_hourly' as source_file
FROM climate_data.raw_era5_hourly
WHERE measurement_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
GROUP BY measurement_date, latitude, longitude;
```

#### Data Quality Checks

```sql
-- Check spatial coverage
SELECT
  measurement_date,
  COUNT(DISTINCT CONCAT(CAST(latitude AS STRING), '_', CAST(longitude AS STRING))) as unique_locations,
  COUNT(*) as total_records,
  MIN(latitude) as min_lat,
  MAX(latitude) as max_lat,
  MIN(longitude) as min_lon,
  MAX(longitude) as max_lon
FROM climate_data.raw_era5_hourly
WHERE measurement_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY measurement_date
ORDER BY measurement_date DESC;

-- Check for extreme temperature values
SELECT
  measurement_date,
  latitude,
  longitude,
  temperature_2m_celsius,
  COUNT(*) as occurrences
FROM climate_data.raw_era5_hourly
WHERE temperature_2m_celsius < -90 OR temperature_2m_celsius > 60
  AND measurement_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY measurement_date, latitude, longitude, temperature_2m_celsius
ORDER BY measurement_date DESC;

-- Validate data completeness (24 hours per day per location)
WITH hourly_counts AS (
  SELECT
    measurement_date,
    latitude,
    longitude,
    COUNT(*) as hours_count
  FROM climate_data.raw_era5_hourly
  WHERE measurement_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  GROUP BY measurement_date, latitude, longitude
)
SELECT
  measurement_date,
  AVG(hours_count) as avg_hours,
  MIN(hours_count) as min_hours,
  MAX(hours_count) as max_hours,
  COUNTIF(hours_count < 24) as locations_with_missing_hours
FROM hourly_counts
GROUP BY measurement_date
ORDER BY measurement_date DESC;
```

---

## Phased Implementation Approach

### Phase 1: Quick Wins (Week 1-2)

**Objective:** Establish data platform foundation with low-complexity datasets

**Datasets:**
1. Global Warming API
2. NASA GISTEMP v4
3. Our World in Data CO2

**Deliverables:**
- BigQuery dataset and schemas created
- Cloud Functions deployed for 3 datasets
- Cloud Scheduler jobs configured
- Basic monitoring dashboards
- Initial data quality checks

**Success Criteria:**
- All 3 pipelines running successfully
- Data refreshing on schedule
- No critical errors in logs
- Data available for querying

**Estimated Effort:** 6-8 days

---

### Phase 2: Core Production (Week 3-5)

**Objective:** Implement medium and high complexity datasets with robust error handling

**Datasets:**
1. NOAA CDO API
2. Copernicus ERA5 (initial implementation)

**Deliverables:**
- Secret Manager integration for API keys
- NOAA pipeline with rate limiting
- ERA5 Cloud Run service
- Wide format tables for analytics
- Enhanced monitoring and alerting
- Data quality framework
- Incremental load patterns

**Success Criteria:**
- NOAA pipeline handling rate limits correctly
- ERA5 processing NetCDF files successfully
- Alerts firing for pipeline failures
- Data quality checks passing
- Documentation complete

**Estimated Effort:** 15-21 days

---

### Phase 3: Optimization & Scale (Week 6+)

**Objective:** Optimize performance, reduce costs, scale to full coverage

**Enhancements:**
- Expand ERA5 spatial/temporal coverage
- Add more NOAA stations
- Implement Dataflow for large-scale processing
- Create materialized views for common queries
- Implement BI Engine for dashboards
- Set up automated data quality reports
- Implement data lineage tracking
- Create data catalog entries

**Success Criteria:**
- Query performance < 5 seconds for common patterns
- Monthly cloud costs within budget
- 99.5% pipeline success rate
- Full documentation and runbooks

**Estimated Effort:** Ongoing

---

## Infrastructure as Code

### Required Terraform Modules

Based on your existing modules, here are the required configurations:

#### 1. BigQuery Module (`/infrastructure/terraform/modules/bigquery`)

```hcl
# modules/bigquery/climate_dataset.tf

resource "google_bigquery_dataset" "climate_data" {
  dataset_id                  = "climate_data"
  project                     = var.project_id
  location                    = var.region
  description                 = "Climate data warehouse for multi-source climate datasets"
  default_table_expiration_ms = null

  access {
    role          = "OWNER"
    user_by_email = var.data_owner_email
  }

  access {
    role          = "READER"
    group_by_email = var.analyst_group_email
  }

  labels = {
    environment = var.environment
    domain      = "climate"
    managed_by  = "terraform"
  }
}

# Create tables (example for one table)
resource "google_bigquery_table" "raw_gw_temperature" {
  dataset_id = google_bigquery_dataset.climate_data.dataset_id
  table_id   = "raw_gw_temperature"
  project    = var.project_id

  time_partitioning {
    type  = "DAY"
    field = "measurement_date"
    require_partition_filter = false
  }

  clustering = ["ingestion_timestamp"]

  schema = file("${path.module}/schemas/raw_gw_temperature.json")

  labels = {
    source = "global-warming-api"
  }
}
```

#### 2. Cloud Functions Module (`/infrastructure/terraform/modules/cloud-functions`)

```hcl
# modules/cloud-functions/climate_ingest.tf

resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-climate-functions"
  location = var.region

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# Global Warming API Function
resource "google_cloudfunctions_function" "global_warming_ingest" {
  name        = "global-warming-api-ingest"
  runtime     = "python311"
  entry_point = "ingest_global_warming_data"

  available_memory_mb   = 512
  timeout               = 540
  max_instances         = 5

  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.gw_function_source.name

  trigger_http = true

  environment_variables = {
    PROJECT_ID = var.project_id
  }

  labels = {
    environment = var.environment
    pipeline    = "climate-global-warming"
  }
}

resource "google_storage_bucket_object" "gw_function_source" {
  name   = "global-warming-ingest-${data.archive_file.gw_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.gw_source.output_path
}

data "archive_file" "gw_source" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/global-warming-ingest"
  output_path = "/tmp/gw-ingest.zip"
}

# Similar resources for other functions...
```

#### 3. Storage Module (`/infrastructure/terraform/modules/storage`)

```hcl
# modules/storage/climate_staging.tf

resource "google_storage_bucket" "climate_staging" {
  name          = "${var.project_id}-climate-staging"
  location      = var.region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 7
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  versioning {
    enabled = false
  }

  labels = {
    purpose     = "climate-data-staging"
    environment = var.environment
  }
}

# Folder organization
resource "google_storage_bucket_object" "era5_folder" {
  name    = "era5/"
  content = "ERA5 reanalysis data"
  bucket  = google_storage_bucket.climate_staging.name
}
```

#### 4. Security Module (`/infrastructure/terraform/modules/security`)

```hcl
# modules/security/climate_secrets.tf

resource "google_secret_manager_secret" "noaa_api_token" {
  secret_id = "noaa-cdo-api-token"

  replication {
    automatic = true
  }

  labels = {
    purpose = "noaa-api-access"
  }
}

resource "google_secret_manager_secret_version" "noaa_api_token" {
  secret      = google_secret_manager_secret.noaa_api_token.id
  secret_data = var.noaa_api_token
}

resource "google_secret_manager_secret_iam_member" "noaa_token_access" {
  secret_id = google_secret_manager_secret.noaa_api_token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

# Similar for CDS API credentials
```

#### 5. Monitoring Module (`/infrastructure/terraform/modules/monitoring`)

```hcl
# modules/monitoring/climate_dashboards.tf

resource "google_monitoring_dashboard" "climate_pipelines" {
  dashboard_json = jsonencode({
    displayName = "Climate Data Pipelines"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Pipeline Success Rate"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\""
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# Alert policies
resource "google_monitoring_alert_policy" "function_failures" {
  display_name = "Climate Pipeline Failures"
  combiner     = "OR"

  conditions {
    display_name = "Function execution errors"

    condition_threshold {
      filter          = "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.label.status=\"error\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [var.notification_channel_id]

  alert_strategy {
    auto_close = "1800s"
  }
}
```

#### 6. Complete Environment Configuration

```hcl
# environments/dev/climate_data.tf

module "climate_bigquery" {
  source = "../../modules/bigquery"

  project_id           = var.project_id
  region               = var.region
  environment          = "dev"
  data_owner_email     = var.data_owner_email
  analyst_group_email  = var.analyst_group_email
}

module "climate_functions" {
  source = "../../modules/cloud-functions"

  project_id  = var.project_id
  region      = var.region
  environment = "dev"

  depends_on = [module.climate_bigquery]
}

module "climate_storage" {
  source = "../../modules/storage"

  project_id  = var.project_id
  region      = var.region
  environment = "dev"
}

module "climate_secrets" {
  source = "../../modules/security"

  project_id       = var.project_id
  noaa_api_token   = var.noaa_api_token
  cds_api_uid      = var.cds_api_uid
  cds_api_key      = var.cds_api_key
}

module "climate_monitoring" {
  source = "../../modules/monitoring"

  project_id              = var.project_id
  notification_channel_id = var.notification_channel_id
}

# Cloud Scheduler jobs
resource "google_cloud_scheduler_job" "global_warming_monthly" {
  name     = "global-warming-api-monthly"
  schedule = "0 2 5 * *"
  time_zone = "UTC"

  http_target {
    uri         = module.climate_functions.global_warming_function_url
    http_method = "POST"
  }
}

# Similar for other scheduler jobs...
```

---

## Monitoring and Alerting

### Cloud Monitoring Dashboard

Create a comprehensive dashboard for all climate pipelines:

**Dashboard JSON Configuration:**

```json
{
  "displayName": "Climate Data Platform - Operations",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Pipeline Success Rate (24h)",
          "scorecard": {
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\"",
                "aggregation": {
                  "alignmentPeriod": "86400s",
                  "perSeriesAligner": "ALIGN_RATE",
                  "crossSeriesReducer": "REDUCE_SUM"
                }
              }
            },
            "sparkChartView": {
              "sparkChartType": "SPARK_LINE"
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Data Freshness (hours since last update)",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"bigquery_dataset\"",
                    "aggregation": {
                      "alignmentPeriod": "3600s"
                    }
                  }
                },
                "plotType": "LINE"
              }
            ]
          }
        }
      },
      {
        "width": 12,
        "height": 4,
        "widget": {
          "title": "Error Rates by Pipeline",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"cloud_function\" AND metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND metric.label.status=\"error\"",
                    "aggregation": {
                      "alignmentPeriod": "3600s",
                      "perSeriesAligner": "ALIGN_RATE",
                      "crossSeriesReducer": "REDUCE_SUM",
                      "groupByFields": ["resource.function_name"]
                    }
                  }
                },
                "plotType": "STACKED_BAR"
              }
            ]
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "BigQuery Storage (GB)",
          "scorecard": {
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"bigquery_dataset\" AND metric.type=\"bigquery.googleapis.com/storage/stored_bytes\"",
                "aggregation": {
                  "alignmentPeriod": "86400s",
                  "perSeriesAligner": "ALIGN_MEAN"
                }
              }
            }
          }
        }
      },
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Query Cost (last 7 days)",
          "scorecard": {
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"bigquery_project\" AND metric.type=\"bigquery.googleapis.com/query/scanned_bytes_billed\""
              }
            }
          }
        }
      }
    ]
  }
}
```

### Alert Policies

**1. Pipeline Failure Alert**
```yaml
display_name: "Climate Pipeline Execution Failure"
conditions:
  - display_name: "Function errors > 0"
    condition_threshold:
      filter: |
        resource.type = "cloud_function"
        metric.type = "cloudfunctions.googleapis.com/function/execution_count"
        metric.labels.status = "error"
      comparison: COMPARISON_GT
      threshold_value: 0
      duration: 60s
notification_channels: [CHANNEL_ID]
```

**2. Data Freshness Alert**
```sql
-- Scheduled query to check data freshness
SELECT
  'global_warming_temperature' as pipeline,
  DATE_DIFF(CURRENT_DATE(), MAX(measurement_date), DAY) as days_old
FROM climate_data.raw_gw_temperature
HAVING days_old > 35  -- Alert if data older than 35 days

UNION ALL

SELECT
  'nasa_gistemp' as pipeline,
  DATE_DIFF(CURRENT_DATE(), MAX(measurement_date), DAY) as days_old
FROM climate_data.raw_gistemp_global
WHERE hemisphere = 'Global'
HAVING days_old > 45

-- Set up alert on this query results
```

**3. Cost Anomaly Alert**
```yaml
display_name: "BigQuery Cost Anomaly"
conditions:
  - display_name: "Daily cost increase > 50%"
    condition_threshold:
      filter: |
        resource.type = "bigquery_project"
        metric.type = "bigquery.googleapis.com/query/scanned_bytes_billed"
      comparison: COMPARISON_GT
      threshold_value: 1099511627776  # 1 TB in bytes
      duration: 86400s
```

---

## Cost Estimation

### Monthly Cost Breakdown (Estimates)

#### Storage Costs

| Dataset | Size/Month | Storage Class | Monthly Cost |
|---------|-----------|---------------|--------------|
| Global Warming API | ~10 MB | Standard | $0.00 |
| NASA GISTEMP | ~50 MB | Standard | $0.01 |
| OWID CO2 | ~100 MB | Standard | $0.02 |
| NOAA CDO (6 stations) | ~500 MB | Standard | $0.10 |
| ERA5 (sampled) | ~50 GB | Standard → Nearline | $1.25 |
| **Total Storage** | ~50 GB | | **$1.38** |

#### Compute Costs

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| Cloud Functions (Gen 2) | ~150 invocations/month | $0.50 |
| Cloud Run (ERA5) | ~30 runs × 20min | $3.00 |
| Cloud Scheduler | 5 jobs | $0.50 |
| **Total Compute** | | **$4.00** |

#### BigQuery Costs

| Operation | Volume | Monthly Cost |
|-----------|--------|--------------|
| Query Processing (on-demand) | ~500 GB/month | $2.50 |
| Storage | 50 GB active | $1.00 |
| Streaming Inserts | Minimal (batch loading) | $0.00 |
| **Total BigQuery** | | **$3.50** |

#### Networking Costs

| Transfer | Volume | Monthly Cost |
|----------|--------|--------------|
| Egress (API downloads) | ~50 GB | $0.00 (first 200 GB free) |
| **Total Networking** | | **$0.00** |

#### Total Monthly Cost

| Category | Cost |
|----------|------|
| Storage | $1.38 |
| Compute | $4.00 |
| BigQuery | $3.50 |
| Networking | $0.00 |
| **Total** | **$8.88** |

**Note:** Costs will increase with:
- Full ERA5 spatial coverage (could reach $50-100/month)
- More NOAA stations
- Higher query frequency
- Additional users

### Cost Optimization Recommendations

1. **Use Flat-Rate BigQuery** if query volume exceeds 40 TB/month ($0.06/GB on-demand vs flat-rate)
2. **Implement BI Engine** for frequently accessed dashboards ($0.30/GB/month for 10 GB)
3. **Archive old ERA5 data** to Coldline storage after 90 days
4. **Use table expiration** for temporary/staging tables
5. **Cluster and partition** all large tables
6. **Sample ERA5 data** spatially (every 5th grid point reduces volume by 25x)

---

## Testing Strategy

### Unit Testing

**Test Cloud Function Locally:**

```python
# tests/test_global_warming_ingest.py

import pytest
from unittest.mock import Mock, patch
from main import ingest_global_warming_data

def test_generate_record_id():
    from main import generate_record_id

    record_id = generate_record_id('temperature', '2020-01-01')
    assert len(record_id) == 32  # MD5 hash length
    assert record_id == generate_record_id('temperature', '2020-01-01')  # Deterministic

def test_parse_time_to_date():
    from main import parse_time_to_date
    from datetime import date

    # Test decimal format
    result = parse_time_to_date('2020.0417')
    assert result == date(2020, 1, 1)

    # Test ISO format
    result = parse_time_to_date('2020-06-15')
    assert result == date(2020, 6, 15)

@patch('main.requests.get')
@patch('main.bigquery.Client')
def test_fetch_and_load_endpoint(mock_bq_client, mock_requests):
    # Mock API response
    mock_response = Mock()
    mock_response.json.return_value = {
        'temperature': [
            {'time': '2020.0417', 'station': 0.5, 'land': 0.6}
        ]
    }
    mock_requests.return_value = mock_response

    # Mock BigQuery client
    mock_client = Mock()
    mock_job = Mock()
    mock_client.load_table_from_json.return_value = mock_job
    mock_bq_client.return_value = mock_client

    # Test function
    from main import fetch_and_load_endpoint, API_ENDPOINTS

    count = fetch_and_load_endpoint(
        mock_client,
        'temperature',
        API_ENDPOINTS['temperature']
    )

    assert count == 1
    mock_client.load_table_from_json.assert_called_once()
```

### Integration Testing

**Test End-to-End Pipeline:**

```python
# tests/integration/test_pipelines.py

import pytest
from google.cloud import bigquery
from datetime import datetime, date, timedelta
import requests

PROJECT_ID = 'your-test-project'
DATASET_ID = 'climate_data_test'

@pytest.fixture(scope='module')
def bq_client():
    return bigquery.Client(project=PROJECT_ID)

def test_global_warming_pipeline_e2e(bq_client):
    """Test Global Warming API pipeline end-to-end"""

    # Trigger Cloud Function
    function_url = 'https://us-central1-PROJECT.cloudfunctions.net/global-warming-api-ingest'
    response = requests.post(function_url)

    assert response.status_code == 200
    result = response.json()
    assert result['status'] == 'completed'
    assert result['total_records'] > 0

    # Verify data in BigQuery
    query = f"""
    SELECT COUNT(*) as count
    FROM `{PROJECT_ID}.{DATASET_ID}.raw_gw_temperature`
    WHERE ingestion_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
    """

    query_job = bq_client.query(query)
    results = list(query_job.result())

    assert results[0]['count'] > 0

def test_data_freshness(bq_client):
    """Test that data is fresh"""

    query = f"""
    SELECT
      MAX(measurement_date) as latest_date,
      DATE_DIFF(CURRENT_DATE(), MAX(measurement_date), DAY) as days_old
    FROM `{PROJECT_ID}.{DATASET_ID}.raw_gw_temperature`
    """

    query_job = bq_client.query(query)
    results = list(query_job.result())

    assert results[0]['days_old'] < 35  # Data should be less than 35 days old

def test_data_quality_no_duplicates(bq_client):
    """Test that there are no duplicate records"""

    query = f"""
    SELECT
      record_id,
      COUNT(*) as count
    FROM `{PROJECT_ID}.{DATASET_ID}.raw_gw_temperature`
    GROUP BY record_id
    HAVING COUNT(*) > 1
    """

    query_job = bq_client.query(query)
    results = list(query_job.result())

    assert len(results) == 0  # No duplicates
```

### Load Testing

**Test Pipeline Scalability:**

```python
# tests/load/test_concurrency.py

import concurrent.futures
import requests
import time

def trigger_pipeline(pipeline_url):
    """Trigger a pipeline and return response time"""
    start_time = time.time()
    response = requests.post(pipeline_url)
    duration = time.time() - start_time

    return {
        'status_code': response.status_code,
        'duration': duration
    }

def test_concurrent_pipeline_triggers():
    """Test pipeline under concurrent load"""

    pipeline_url = 'https://us-central1-PROJECT.cloudfunctions.net/global-warming-api-ingest'
    num_concurrent = 10

    with concurrent.futures.ThreadPoolExecutor(max_workers=num_concurrent) as executor:
        futures = [executor.submit(trigger_pipeline, pipeline_url) for _ in range(num_concurrent)]
        results = [f.result() for f in concurrent.futures.as_completed(futures)]

    # Verify all succeeded
    success_count = sum(1 for r in results if r['status_code'] == 200)
    assert success_count == num_concurrent

    # Check average response time
    avg_duration = sum(r['duration'] for r in results) / len(results)
    print(f"Average response time: {avg_duration:.2f}s")
    assert avg_duration < 30  # Should complete within 30 seconds
```

### Data Quality Testing

**Automated Data Quality Suite:**

```sql
-- tests/data_quality/climate_data_quality.sql

-- Test 1: Check for required fields
CREATE TEMP TABLE dq_results AS
SELECT
  'raw_gw_temperature' as table_name,
  'null_check' as test_name,
  COUNTIF(measurement_date IS NULL) as failures,
  COUNT(*) as total_records
FROM climate_data.raw_gw_temperature
WHERE ingestion_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)

UNION ALL

-- Test 2: Check for future dates
SELECT
  'raw_gw_temperature' as table_name,
  'future_date_check' as test_name,
  COUNTIF(measurement_date > CURRENT_DATE()) as failures,
  COUNT(*) as total_records
FROM climate_data.raw_gw_temperature
WHERE ingestion_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)

UNION ALL

-- Test 3: Check temperature anomaly ranges
SELECT
  'raw_gistemp_global' as table_name,
  'temperature_range_check' as test_name,
  COUNTIF(temperature_anomaly < -5 OR temperature_anomaly > 5) as failures,
  COUNT(*) as total_records
FROM climate_data.raw_gistemp_global
WHERE ingestion_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR);

-- Verify all tests passed
SELECT
  *,
  CASE WHEN failures = 0 THEN 'PASS' ELSE 'FAIL' END as status
FROM dq_results
WHERE failures > 0;  -- Show only failures
```

---

## Appendix

### A. Useful BigQuery Queries

#### Unified Climate View

```sql
-- Create unified view of all climate metrics
CREATE OR REPLACE VIEW climate_data.unified_climate_metrics AS

-- Temperature from Global Warming API
SELECT
  measurement_date,
  'Global Warming API' as source,
  'Temperature Anomaly' as metric,
  land as value,
  'Celsius' as unit,
  NULL as location,
  NULL as latitude,
  NULL as longitude
FROM climate_data.raw_gw_temperature

UNION ALL

-- Temperature from NASA GISTEMP
SELECT
  measurement_date,
  'NASA GISTEMP' as source,
  CONCAT('Temperature Anomaly - ', hemisphere) as metric,
  temperature_anomaly as value,
  'Celsius' as unit,
  hemisphere as location,
  NULL as latitude,
  NULL as longitude
FROM climate_data.raw_gistemp_global

UNION ALL

-- CO2 from Global Warming API
SELECT
  measurement_date,
  'Global Warming API' as source,
  'CO2 Concentration' as metric,
  trend as value,
  'ppm' as unit,
  NULL as location,
  NULL as latitude,
  NULL as longitude
FROM climate_data.raw_gw_co2

UNION ALL

-- CO2 from OWID
SELECT
  DATE(year, 1, 1) as measurement_date,
  'Our World in Data' as source,
  'CO2 Emissions' as metric,
  co2 as value,
  'million tonnes' as unit,
  country as location,
  NULL as latitude,
  NULL as longitude
FROM climate_data.raw_owid_co2
WHERE iso_code = 'OWID_WRL';  -- World total
```

#### Climate Trends Analysis

```sql
-- Analyze temperature trends over decades
WITH decade_temps AS (
  SELECT
    FLOOR(year / 10) * 10 as decade,
    AVG(temperature_anomaly) as avg_anomaly,
    COUNT(*) as months_count
  FROM climate_data.raw_gistemp_global
  WHERE hemisphere = 'Global'
  GROUP BY decade
)
SELECT
  decade,
  avg_anomaly,
  months_count,
  avg_anomaly - LAG(avg_anomaly) OVER (ORDER BY decade) as decade_change,
  RANK() OVER (ORDER BY avg_anomaly DESC) as warmest_decade_rank
FROM decade_temps
ORDER BY decade;
```

#### Emissions Leaders

```sql
-- Top CO2 emitters by year
WITH latest_year AS (
  SELECT MAX(year) as max_year
  FROM climate_data.raw_owid_co2
)
SELECT
  country,
  year,
  co2 as total_co2_mt,
  co2_per_capita,
  population,
  RANK() OVER (PARTITION BY year ORDER BY co2 DESC) as rank_by_total
FROM climate_data.raw_owid_co2
WHERE year >= (SELECT max_year FROM latest_year) - 10
  AND iso_code IS NOT NULL
  AND co2 IS NOT NULL
QUALIFY rank_by_total <= 10
ORDER BY year DESC, rank_by_total;
```

### B. Troubleshooting Guide

#### Issue: Cloud Function Timeout

**Symptoms:**
- Function exceeds 540s timeout
- Incomplete data loads

**Solutions:**
1. Increase timeout (max 540s for HTTP functions)
2. Process data in batches
3. Use Cloud Run for longer-running tasks
4. Implement pagination for large datasets

#### Issue: BigQuery Load Job Fails

**Symptoms:**
- Error: "Invalid schema"
- Error: "Too many requests"

**Solutions:**
```python
# Add retry logic
from google.api_core import retry

@retry.Retry(predicate=retry.if_exception_type(exceptions.TooManyRequests))
def load_to_bigquery(client, rows, table_id):
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        schema_update_options=[
            bigquery.SchemaUpdateOption.ALLOW_FIELD_ADDITION
        ]
    )

    job = client.load_table_from_json(rows, table_id, job_config=job_config)
    return job.result()
```

#### Issue: NOAA API Rate Limit Exceeded

**Symptoms:**
- HTTP 429 errors
- "Rate limit exceeded" messages

**Solutions:**
```python
import time
from functools import wraps

def rate_limit(max_per_second):
    min_interval = 1.0 / max_per_second
    last_called = [0.0]

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            elapsed = time.time() - last_called[0]
            left_to_wait = min_interval - elapsed
            if left_to_wait > 0:
                time.sleep(left_to_wait)
            ret = func(*args, **kwargs)
            last_called[0] = time.time()
            return ret
        return wrapper
    return decorator

@rate_limit(5)  # 5 requests per second
def fetch_noaa_data(api_token, params):
    # API call implementation
    pass
```

#### Issue: ERA5 NetCDF Processing Memory Error

**Symptoms:**
- Out of memory errors
- Cloud Run container crashes

**Solutions:**
1. Increase Cloud Run memory to 8 GB
2. Process NetCDF in chunks:

```python
import xarray as xr

def process_netcdf_chunked(file_path, chunk_size=1000):
    ds = xr.open_dataset(file_path, chunks={'time': 24, 'latitude': 10, 'longitude': 10})

    for i in range(0, len(ds.time), chunk_size):
        chunk = ds.isel(time=slice(i, i + chunk_size))
        # Process chunk
        yield chunk

    ds.close()
```

### C. Reference Links

**Official Documentation:**
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Cloud Scheduler Documentation](https://cloud.google.com/scheduler/docs)
- [Secret Manager Documentation](https://cloud.google.com/secret-manager/docs)

**API Documentation:**
- [NOAA CDO API](https://www.ncdc.noaa.gov/cdo-web/webservices/v2)
- [Copernicus CDS API](https://cds.climate.copernicus.eu/api-how-to)
- [NASA GISTEMP](https://data.giss.nasa.gov/gistemp/)

**Climate Data Resources:**
- [Our World in Data - CO2](https://github.com/owid/co2-data)
- [Global Warming API](https://global-warming.org/api)

### D. Contact and Support

**Data Engineering Team:**
- Email: data-engineering@example.com
- Slack: #climate-data-platform

**On-Call Rotation:**
- PagerDuty: climate-data-pipelines

**Documentation:**
- Confluence: Climate Data Platform
- GitHub: climate-data-pipelines repository

---

## Conclusion

This guide provides a complete implementation roadmap for ingesting five climate datasets into a GCP-based data platform. The phased approach ensures quick wins while building toward production-ready pipelines with robust error handling, monitoring, and cost optimization.

**Next Steps:**
1. Review and approve infrastructure requirements
2. Set up GCP project and enable required APIs
3. Begin Phase 1 implementation (Quick Wins)
4. Schedule regular reviews and optimization cycles

**Success Metrics:**
- Pipeline uptime > 99.5%
- Data freshness < 24 hours for daily updates
- Query performance < 5 seconds for common patterns
- Monthly cloud costs within budget ($10-50/month)

**Maintenance:**
- Weekly: Review pipeline logs and error rates
- Monthly: Optimize queries and storage costs
- Quarterly: Update dependencies and review data quality metrics
- Annually: Major version upgrades and architecture review
