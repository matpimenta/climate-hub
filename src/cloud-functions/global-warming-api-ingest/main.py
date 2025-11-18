"""
Global Warming API Ingestion Cloud Function

This Cloud Function ingests climate data from the Global Warming API into BigQuery.
It fetches temperature anomalies, CO2, methane, and nitrous oxide concentrations.

Data sources:
- Temperature: https://global-warming.org/api/temperature-api
- CO2: https://global-warming.org/api/co2-api
- Methane: https://global-warming.org/api/methane-api
- Nitrous Oxide: https://global-warming.org/api/nitrous-oxide-api
"""

import functions_framework
import requests
from google.cloud import bigquery
from datetime import datetime, date
import hashlib
import logging
import os
import json

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration from environment variables
PROJECT_ID = os.environ.get('GCP_PROJECT', os.environ.get('GOOGLE_CLOUD_PROJECT'))
DATASET_ID = os.environ.get('DATASET_ID', 'climate_data')

API_ENDPOINTS = {
    'temperature': {
        'url': 'https://global-warming.org/api/temperature-api',
        'table': 'raw_gw_temperature',
        'fields': ['time', 'station', 'land'],
        'data_key': 'result'  # Key in API response
    },
    'co2': {
        'url': 'https://global-warming.org/api/co2-api',
        'table': 'raw_gw_co2',
        'fields': ['year', 'month', 'day', 'cycle', 'trend'],
        'data_key': 'co2'
    },
    'methane': {
        'url': 'https://global-warming.org/api/methane-api',
        'table': 'raw_gw_methane',
        'fields': ['date', 'average', 'trend'],
        'data_key': 'methane'
    },
    'nitrous-oxide': {
        'url': 'https://global-warming.org/api/nitrous-oxide-api',
        'table': 'raw_gw_nitrous_oxide',
        'fields': ['date', 'average', 'trend'],
        'data_key': 'nitrous'
    }
}


def generate_record_id(endpoint_name: str, time_value: str) -> str:
    """Generate unique record ID from endpoint name and time value."""
    composite = f"{endpoint_name}_{time_value}"
    return hashlib.md5(composite.encode()).hexdigest()


def parse_time_to_date(time_str: str, endpoint_name: str) -> date:
    """
    Parse time string to date.
    Handles different formats from different API endpoints.
    """
    try:
        if endpoint_name == 'temperature':
            # Temperature API uses decimal format like "1880.0417"
            if '.' in str(time_str):
                year = int(float(time_str))
                month_decimal = float(time_str) - year
                month = max(1, min(12, int(month_decimal * 12) + 1))
                return date(year, month, 1)
            else:
                return datetime.strptime(str(time_str), '%Y-%m-%d').date()

        elif endpoint_name == 'co2':
            # CO2 API has year, month, day fields
            return date(int(time_str['year']), int(time_str['month']), int(time_str['day']))

        elif endpoint_name in ['methane', 'nitrous-oxide']:
            # These APIs use YYYY-MM format
            if isinstance(time_str, str) and '-' in time_str:
                parts = time_str.split('-')
                return date(int(parts[0]), int(parts[1]), 1)

        logger.warning(f"Unexpected time format for {endpoint_name}: {time_str}")
        return None

    except Exception as e:
        logger.warning(f"Failed to parse date {time_str} for {endpoint_name}: {e}")
        return None


def fetch_and_load_endpoint(client: bigquery.Client, endpoint_name: str, config: dict):
    """Fetch data from an API endpoint and load it into BigQuery."""
    logger.info(f"Fetching data from {endpoint_name} endpoint: {config['url']}")

    try:
        # Fetch data from API with timeout
        response = requests.get(config['url'], timeout=30)
        response.raise_for_status()
        data = response.json()

        # Extract the actual data array using the data_key
        data_key = config.get('data_key', endpoint_name)
        if data_key not in data:
            logger.warning(f"No data key '{data_key}' found in response for {endpoint_name}")
            return 0

        records = data[data_key]
        logger.info(f"Fetched {len(records)} records from {endpoint_name}")

        # Transform data for BigQuery
        rows_to_insert = []
        ingestion_time = datetime.utcnow().isoformat()

        for record in records:
            try:
                # Parse measurement date based on endpoint type
                if endpoint_name == 'co2':
                    measurement_date = parse_time_to_date(record, endpoint_name)
                    time_identifier = f"{record.get('year')}-{record.get('month')}-{record.get('day')}"
                elif endpoint_name == 'temperature':
                    time_value = record.get('time', '')
                    measurement_date = parse_time_to_date(time_value, endpoint_name)
                    time_identifier = time_value
                else:  # methane or nitrous-oxide
                    date_value = record.get('date', '')
                    measurement_date = parse_time_to_date(date_value, endpoint_name)
                    time_identifier = date_value

                if not measurement_date:
                    continue

                # Create base row
                row = {
                    'record_id': generate_record_id(endpoint_name, time_identifier),
                    'measurement_date': measurement_date.isoformat(),
                    'ingestion_timestamp': ingestion_time,
                    'source_file': config['url']
                }

                # Add endpoint-specific fields
                if endpoint_name == 'temperature':
                    row['land'] = float(record.get('land')) if record.get('land') else None
                    row['station'] = float(record.get('station')) if record.get('station') else None
                    row['time'] = record.get('time')
                elif endpoint_name == 'co2':
                    row['cycle'] = float(record.get('cycle')) if record.get('cycle') else None
                    row['trend'] = float(record.get('trend')) if record.get('trend') else None
                elif endpoint_name in ['methane', 'nitrous-oxide']:
                    row['average'] = float(record.get('average')) if record.get('average') else None
                    row['trend'] = float(record.get('trend')) if record.get('trend') else None

                rows_to_insert.append(row)

            except Exception as e:
                logger.warning(f"Failed to process record in {endpoint_name}: {e}")
                continue

        if not rows_to_insert:
            logger.warning(f"No valid records to insert for {endpoint_name}")
            return 0

        # Load to BigQuery using WRITE_TRUNCATE to replace existing data
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

        logger.info(f"Successfully loaded {len(rows_to_insert)} rows to {table_id}")
        return len(rows_to_insert)

    except requests.exceptions.RequestException as e:
        logger.error(f"HTTP request failed for {endpoint_name}: {e}")
        raise
    except Exception as e:
        logger.error(f"Failed to load {endpoint_name}: {e}")
        raise


@functions_framework.http
def ingest_global_warming_data(request):
    """
    HTTP Cloud Function to ingest Global Warming API data into BigQuery.

    This function can be triggered by Cloud Scheduler or manual HTTP request.
    """

    try:
        logger.info(f"Starting Global Warming API ingestion - Project: {PROJECT_ID}, Dataset: {DATASET_ID}")

        # Initialize BigQuery client
        client = bigquery.Client(project=PROJECT_ID)

        results = {}
        total_records = 0

        # Process each API endpoint
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
                logger.error(f"Failed to process {endpoint_name}: {e}")

        # Determine overall status
        success_count = sum(1 for r in results.values() if r['status'] == 'success')
        overall_status = 'completed' if success_count == len(API_ENDPOINTS) else 'partial_failure'

        response_data = {
            'status': overall_status,
            'timestamp': datetime.utcnow().isoformat(),
            'total_records': total_records,
            'endpoints_processed': len(API_ENDPOINTS),
            'endpoints_succeeded': success_count,
            'details': results
        }

        logger.info(f"Ingestion complete: {success_count}/{len(API_ENDPOINTS)} endpoints succeeded, {total_records} total records")

        return response_data, 200

    except Exception as e:
        logger.error(f"Pipeline failed with error: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500
