"""
NASA GISTEMP v4 Ingestion Cloud Function

This Cloud Function ingests temperature anomaly data from NASA's Goddard Institute
for Space Studies Surface Temperature Analysis (GISTEMP v4) into BigQuery.

Data sources:
- Global: https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv
- Northern Hemisphere: https://data.giss.nasa.gov/gistemp/tabledata_v4/NH.Ts+dSST.csv
- Southern Hemisphere: https://data.giss.nasa.gov/gistemp/tabledata_v4/SH.Ts+dSST.csv
- Zonal Annual: https://data.giss.nasa.gov/gistemp/tabledata_v4/ZonAnn.Ts+dSST.csv
"""

import functions_framework
import requests
from google.cloud import bigquery
from datetime import datetime, date
import hashlib
import csv
import io
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuration from environment variables
PROJECT_ID = os.environ.get('GCP_PROJECT', os.environ.get('GOOGLE_CLOUD_PROJECT'))
DATASET_ID = os.environ.get('DATASET_ID', 'climate_data')

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
    """Generate unique record ID from hemisphere, year, and optional month."""
    if month:
        composite = f"gistemp_{hemisphere}_{year}_{month:02d}"
    else:
        composite = f"gistemp_{hemisphere}_{year}"
    return hashlib.md5(composite.encode()).hexdigest()


def parse_gistemp_csv(csv_content: str, source_type: str, hemisphere: str = None) -> list:
    """
    Parse NASA GISTEMP CSV format.

    Args:
        csv_content: Raw CSV content as string
        source_type: Type of source ('monthly' or 'zonal')
        hemisphere: Hemisphere identifier for monthly data

    Returns:
        List of dictionaries ready for BigQuery insertion
    """
    rows = []
    reader = csv.DictReader(io.StringIO(csv_content))

    for row in reader:
        try:
            year = int(row['Year'])

            if source_type == 'zonal':
                # Zonal annual data - one row per zone per year
                for zone_name, value in row.items():
                    if zone_name == 'Year':
                        continue

                    try:
                        temp_anomaly = float(value)
                        # NASA uses 999.9 as missing data indicator
                        if temp_anomaly == 999.9 or temp_anomaly > 900:
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
                # Monthly data - one row per month per year
                for month_idx, month_name in enumerate(MONTH_NAMES, 1):
                    if month_name not in row:
                        continue

                    try:
                        temp_anomaly = float(row[month_name])
                        # NASA uses 999.9 as missing data indicator
                        if temp_anomaly == 999.9 or temp_anomaly > 900:
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
    """
    Fetch GISTEMP data from NASA servers and load to BigQuery.

    Uses MERGE strategy for monthly data to handle updates, and TRUNCATE for zonal data.
    """
    logger.info(f"Fetching data from {source_name}: {config['url']}")

    try:
        # Download CSV from NASA
        response = requests.get(config['url'], timeout=60)
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

        if source_type == 'monthly':
            # For monthly data, use MERGE to handle updates
            # Create temporary table for staging
            temp_table_id = f"{table_id}_temp_{int(datetime.utcnow().timestamp())}"

            job_config = bigquery.LoadJobConfig(
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            )

            job = client.load_table_from_json(rows, temp_table_id, job_config=job_config)
            job.result()

            logger.info(f"Loaded {len(rows)} rows to temp table {temp_table_id}")

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

            logger.info(f"Merged data into {table_id}")

            # Delete temp table
            client.delete_table(temp_table_id, not_found_ok=True)

        else:
            # For zonal data, truncate and reload (annual summary data)
            job_config = bigquery.LoadJobConfig(
                write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
            )

            job = client.load_table_from_json(rows, table_id, job_config=job_config)
            job.result()

            logger.info(f"Loaded {len(rows)} rows to {table_id}")

        return len(rows)

    except requests.exceptions.RequestException as e:
        logger.error(f"HTTP request failed for {source_name}: {e}")
        raise
    except Exception as e:
        logger.error(f"Failed to load {source_name}: {e}")
        raise


@functions_framework.http
def ingest_gistemp_data(request):
    """
    HTTP Cloud Function to ingest NASA GISTEMP data into BigQuery.

    This function can be triggered by Cloud Scheduler or manual HTTP request.
    """

    try:
        logger.info(f"Starting NASA GISTEMP ingestion - Project: {PROJECT_ID}, Dataset: {DATASET_ID}")

        # Initialize BigQuery client
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
                logger.error(f"Failed to process {source_name}: {e}")

        # Determine overall status
        success_count = sum(1 for r in results.values() if r['status'] == 'success')
        overall_status = 'completed' if success_count == len(DATA_SOURCES) else 'partial_failure'

        response_data = {
            'status': overall_status,
            'timestamp': datetime.utcnow().isoformat(),
            'total_records': total_records,
            'sources_processed': len(DATA_SOURCES),
            'sources_succeeded': success_count,
            'details': results
        }

        logger.info(f"Ingestion complete: {success_count}/{len(DATA_SOURCES)} sources succeeded, {total_records} total records")

        return response_data, 200

    except Exception as e:
        logger.error(f"Pipeline failed with error: {e}")
        return {
            'status': 'failed',
            'error': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }, 500
