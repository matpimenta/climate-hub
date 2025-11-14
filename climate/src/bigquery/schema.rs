// BigQuery schema management

use anyhow::Result;
use serde_json::json;

pub struct SchemaManager {}

impl SchemaManager {
    pub fn new() -> Self {
        Self {}
    }

    /// Get the schema for raw NOAA CDO data
    pub fn noaa_cdo_schema() -> serde_json::Value {
        json!([
            {"name": "source_id", "type": "STRING", "mode": "REQUIRED"},
            {"name": "ingestion_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"},
            {"name": "data_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"},
            {"name": "latitude", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "longitude", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "location_name", "type": "STRING", "mode": "NULLABLE"},
            {"name": "station_id", "type": "STRING", "mode": "REQUIRED"},
            {"name": "datatype", "type": "STRING", "mode": "REQUIRED"},
            {"name": "value", "type": "FLOAT64", "mode": "REQUIRED"},
            {"name": "attributes", "type": "STRING", "mode": "NULLABLE"},
            {"name": "data_quality_flag", "type": "STRING", "mode": "NULLABLE"}
        ])
    }

    /// Get the schema for raw NASA POWER data
    pub fn nasa_power_schema() -> serde_json::Value {
        json!([
            {"name": "source_id", "type": "STRING", "mode": "REQUIRED"},
            {"name": "ingestion_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"},
            {"name": "data_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"},
            {"name": "latitude", "type": "FLOAT64", "mode": "REQUIRED"},
            {"name": "longitude", "type": "FLOAT64", "mode": "REQUIRED"},
            {"name": "location_name", "type": "STRING", "mode": "NULLABLE"},
            {"name": "temperature_2m", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "temperature_2m_max", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "temperature_2m_min", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "precipitation", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "wind_speed", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "relative_humidity", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "solar_radiation", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "data_quality_flag", "type": "STRING", "mode": "NULLABLE"}
        ])
    }

    /// Get the schema for staging weather observations
    pub fn staging_weather_observations_schema() -> serde_json::Value {
        json!([
            {"name": "observation_id", "type": "STRING", "mode": "REQUIRED"},
            {"name": "source_id", "type": "STRING", "mode": "REQUIRED"},
            {"name": "timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"},
            {"name": "latitude", "type": "FLOAT64", "mode": "REQUIRED"},
            {"name": "longitude", "type": "FLOAT64", "mode": "REQUIRED"},
            {"name": "location_name", "type": "STRING", "mode": "NULLABLE"},
            {"name": "temperature_celsius", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "precipitation_mm", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "wind_speed_ms", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "humidity_percent", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "pressure_hpa", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "quality_score", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "processing_timestamp", "type": "TIMESTAMP", "mode": "REQUIRED"}
        ])
    }

    // TODO: Add more schema definitions for other data sources
}
