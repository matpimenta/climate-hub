# Getting Started with Climate Data Platform

This guide will help you set up and start using the Climate Data Platform.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Rust** (1.70 or higher): Install from https://rustup.rs/
- **Google Cloud SDK**: Install from https://cloud.google.com/sdk/docs/install
- **Git**: For version control

## Step 1: Set Up Google Cloud Platform

### 1.1 Create a GCP Project

```bash
# Create a new GCP project
gcloud projects create your-climate-project-id

# Set the project as active
gcloud config set project your-climate-project-id
```

### 1.2 Enable Required APIs

```bash
# Enable BigQuery API
gcloud services enable bigquery.googleapis.com

# Enable Cloud Storage API (for data staging)
gcloud services enable storage.googleapis.com
```

### 1.3 Create a Service Account

```bash
# Create service account
gcloud iam service-accounts create climate-data-sa \
    --display-name="Climate Data Platform Service Account"

# Grant BigQuery Admin role
gcloud projects add-iam-policy-binding your-climate-project-id \
    --member="serviceAccount:climate-data-sa@your-climate-project-id.iam.gserviceaccount.com" \
    --role="roles/bigquery.admin"

# Download credentials
gcloud iam service-accounts keys create ~/climate-data-key.json \
    --iam-account=climate-data-sa@your-climate-project-id.iam.gserviceaccount.com
```

### 1.4 Create BigQuery Dataset

```bash
# Create the main dataset
bq mk --dataset \
    --location=US \
    --description="Climate Data Platform - Main Dataset" \
    your-climate-project-id:climate_data_platform

# Create raw data dataset
bq mk --dataset \
    --location=US \
    your-climate-project-id:climate_data_platform.raw

# Create staging dataset
bq mk --dataset \
    --location=US \
    your-climate-project-id:climate_data_platform.staging

# Create analytics dataset
bq mk --dataset \
    --location=US \
    your-climate-project-id:climate_data_platform.analytics
```

## Step 2: Obtain API Keys

### 2.1 NOAA Climate Data Online (CDO)

1. Visit https://www.ncdc.noaa.gov/cdo-web/token
2. Enter your email address
3. Check your email for the API token
4. Save the token for configuration

### 2.2 Copernicus Climate Data Store (ERA5)

1. Register at https://cds.climate.copernicus.eu/
2. Log in and go to your profile page
3. Copy your API key (UID:API-key format)
4. Accept the license terms for ERA5 data

### 2.3 OpenWeather API

1. Sign up at https://openweathermap.org/api
2. Go to API keys section
3. Generate a new API key
4. Free tier allows 1000 calls/day

### 2.4 OpenAQ API

1. Register at https://openaq.org/
2. Request an API key from your account page
3. Free tier allows 10,000 requests/day

## Step 3: Configure the Application

### 3.1 Copy Environment Template

```bash
cd climate
cp .env.example .env
```

### 3.2 Edit .env File

```bash
# Open the .env file in your editor
nano .env  # or use your preferred editor
```

Fill in the values:

```env
# Google Cloud Platform
GCP_PROJECT_ID=your-climate-project-id
BIGQUERY_DATASET=climate_data_platform
GOOGLE_APPLICATION_CREDENTIALS=/home/yourusername/climate-data-key.json

# NOAA Climate Data Online (CDO)
NOAA_CDO_API_KEY=your_noaa_api_key_here

# OpenWeather
OPENWEATHER_API_KEY=your_openweather_key_here

# Copernicus Climate Data Store (ERA5)
CDS_API_KEY=your_uid:your_api_key
CDS_API_URL=https://cds.climate.copernicus.eu/api/v2

# OpenAQ
OPENAQ_API_KEY=your_openaq_key_here

# Application Settings
RUST_LOG=info
BATCH_SIZE=1000
MAX_RETRIES=3
RETRY_DELAY_MS=1000
```

## Step 4: Build and Test

### 4.1 Build the Project

```bash
# Check for compilation errors
cargo check

# Build in debug mode
cargo build

# Build in release mode (optimized)
cargo build --release
```

### 4.2 Run Tests

```bash
cargo test
```

### 4.3 Run the Application

```bash
# Run in development mode
cargo run

# Run the release build
cargo run --release
```

## Step 5: Verify Setup

### 5.1 Test BigQuery Connection

```bash
# List datasets
bq ls --project_id=your-climate-project-id

# Expected output should show climate_data_platform
```

### 5.2 Test API Connectivity

You can test API endpoints manually:

```bash
# Test NOAA CDO API
curl -H "token: your_noaa_api_key" \
  "https://www.ncdc.noaa.gov/cdo-web/api/v2/datasets"

# Test NASA POWER API (no auth required)
curl "https://power.larc.nasa.gov/api/temporal/daily/point?parameters=T2M&community=RE&longitude=-122.4&latitude=37.8&start=20230101&end=20230131&format=JSON"

# Test OpenWeather API
curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=your_openweather_key"
```

## Step 6: Start Data Ingestion

### 6.1 Ingest First Data Source (NOAA CDO)

```bash
# Run with specific date range
cargo run -- --source noaa_cdo --start-date 2025-01-01 --end-date 2025-01-31
```

### 6.2 Monitor Progress

Check the logs for ingestion progress:
- Success messages indicate data was loaded
- Error messages show any issues with API calls or BigQuery loading

### 6.3 Verify Data in BigQuery

```bash
# Query the raw data
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) as record_count FROM `your-climate-project-id.climate_data_platform.raw_noaa_cdo_daily`'
```

## Next Steps

### Recommended Order of Implementation

Following the [Data Integration Plan](DATA_INTEGRATION_PLAN.md):

1. **Week 1-2**: Complete infrastructure setup (done above)
2. **Week 3-4**: Implement NOAA CDO integration
   - Develop API client
   - Create BigQuery schema
   - Build ETL pipeline
   - Add data validation
3. **Week 5-6**: Add NASA POWER integration
4. **Week 7-8**: Implement ERA5 integration
5. **Continue** following the plan for additional data sources

### Development Workflow

1. **Feature Branch**: Create a new branch for each data source
   ```bash
   git checkout -b feature/nasa-power-integration
   ```

2. **Implement**: Add data source connector in `src/datasources/`

3. **Test**: Write unit tests and integration tests

4. **Document**: Update documentation with any changes

5. **Merge**: Once tested, merge to main branch

### Monitoring and Maintenance

- **Set up Cloud Monitoring**: Create dashboards for data ingestion metrics
- **Configure Alerts**: Set alerts for failed ingestion jobs
- **Cost Monitoring**: Track BigQuery costs and optimize queries
- **Data Quality**: Regularly check data quality metrics

## Troubleshooting

### Common Issues

#### 1. "Permission denied" errors

```bash
# Verify service account permissions
gcloud projects get-iam-policy your-climate-project-id \
  --flatten="bindings[].members" \
  --filter="bindings.members:climate-data-sa@*"
```

#### 2. "Dataset not found" errors

```bash
# Create the dataset if it doesn't exist
bq mk --dataset your-climate-project-id:climate_data_platform
```

#### 3. API rate limit errors

- Wait for the rate limit window to reset
- Implement exponential backoff (already in plan)
- Consider upgrading API tiers if needed

#### 4. Build errors

```bash
# Clean and rebuild
cargo clean
cargo build
```

## Resources

- [Project README](../README.md)
- [Data Integration Plan](DATA_INTEGRATION_PLAN.md)
- [BigQuery Schemas](BIGQUERY_SCHEMAS.md)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Rust Documentation](https://doc.rust-lang.org/)

## Support

For issues or questions:
1. Check the documentation in `docs/`
2. Review the [Data Integration Plan](DATA_INTEGRATION_PLAN.md)
3. Consult API documentation for specific data sources

---

**Last Updated**: 2025-11-14
**Version**: 1.0
