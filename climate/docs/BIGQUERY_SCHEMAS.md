# BigQuery Schema Documentation

This document describes the BigQuery schema design for the Climate Data Platform.

## Database Structure

The platform uses a three-tier architecture:

```
climate_data_platform/
├── raw/           # Raw data as ingested from sources
├── staging/       # Cleaned and normalized data
└── analytics/     # ML-ready aggregated datasets
```

## Naming Conventions

- **Datasets**: `climate_data_platform` (configurable via env)
- **Tables**: `{tier}_{source}_{datatype}`
  - Example: `raw_noaa_cdo_daily`
  - Example: `staging_weather_observations`
  - Example: `analytics_time_series_weather`

## Common Fields

All tables include these standard fields:

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `source_id` | STRING | REQUIRED | Identifier for the data source |
| `ingestion_timestamp` | TIMESTAMP | REQUIRED | When data was loaded into BigQuery |
| `data_timestamp` | TIMESTAMP | REQUIRED | Original timestamp of the measurement |
| `latitude` | FLOAT64 | NULLABLE | Latitude coordinate |
| `longitude` | FLOAT64 | NULLABLE | Longitude coordinate |
| `location_name` | STRING | NULLABLE | Human-readable location name |
| `data_quality_flag` | STRING | NULLABLE | Quality indicator (GOOD, FAIR, POOR, UNKNOWN) |

---

## Raw Layer Schemas

### raw_noaa_cdo_daily

Daily weather observations from NOAA Climate Data Online.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `source_id` | STRING | REQUIRED | "noaa_cdo" |
| `ingestion_timestamp` | TIMESTAMP | REQUIRED | Ingestion time |
| `data_timestamp` | TIMESTAMP | REQUIRED | Observation date |
| `latitude` | FLOAT64 | NULLABLE | Station latitude |
| `longitude` | FLOAT64 | NULLABLE | Station longitude |
| `location_name` | STRING | NULLABLE | Station name |
| `station_id` | STRING | REQUIRED | NOAA station identifier |
| `datatype` | STRING | REQUIRED | Type (TMAX, TMIN, PRCP, etc.) |
| `value` | FLOAT64 | REQUIRED | Measurement value |
| `attributes` | STRING | NULLABLE | Measurement attributes |
| `data_quality_flag` | STRING | NULLABLE | Quality flag |

**Partitioning**: By `data_timestamp` (daily)
**Clustering**: `station_id`, `datatype`

### raw_nasa_power

NASA POWER API solar and meteorological data.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `source_id` | STRING | REQUIRED | "nasa_power" |
| `ingestion_timestamp` | TIMESTAMP | REQUIRED | Ingestion time |
| `data_timestamp` | TIMESTAMP | REQUIRED | Observation date |
| `latitude` | FLOAT64 | REQUIRED | Grid point latitude |
| `longitude` | FLOAT64 | REQUIRED | Grid point longitude |
| `location_name` | STRING | NULLABLE | Location identifier |
| `temperature_2m` | FLOAT64 | NULLABLE | Temperature at 2m (°C) |
| `temperature_2m_max` | FLOAT64 | NULLABLE | Daily max temp (°C) |
| `temperature_2m_min` | FLOAT64 | NULLABLE | Daily min temp (°C) |
| `precipitation` | FLOAT64 | NULLABLE | Precipitation (mm) |
| `wind_speed` | FLOAT64 | NULLABLE | Wind speed (m/s) |
| `relative_humidity` | FLOAT64 | NULLABLE | Relative humidity (%) |
| `solar_radiation` | FLOAT64 | NULLABLE | Solar radiation (MJ/m²/day) |
| `data_quality_flag` | STRING | NULLABLE | Quality flag |

**Partitioning**: By `data_timestamp` (daily)
**Clustering**: `latitude`, `longitude`

### raw_era5_reanalysis

ERA5 atmospheric reanalysis data from Copernicus.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `source_id` | STRING | REQUIRED | "era5" |
| `ingestion_timestamp` | TIMESTAMP | REQUIRED | Ingestion time |
| `data_timestamp` | TIMESTAMP | REQUIRED | Analysis time |
| `latitude` | FLOAT64 | REQUIRED | Grid latitude |
| `longitude` | FLOAT64 | REQUIRED | Grid longitude |
| `pressure_level` | INTEGER | NULLABLE | Pressure level (hPa) |
| `temperature` | FLOAT64 | NULLABLE | Temperature (K) |
| `u_wind` | FLOAT64 | NULLABLE | U wind component (m/s) |
| `v_wind` | FLOAT64 | NULLABLE | V wind component (m/s) |
| `specific_humidity` | FLOAT64 | NULLABLE | Specific humidity (kg/kg) |
| `geopotential` | FLOAT64 | NULLABLE | Geopotential (m²/s²) |
| `surface_pressure` | FLOAT64 | NULLABLE | Surface pressure (Pa) |
| `total_precipitation` | FLOAT64 | NULLABLE | Total precipitation (m) |
| `data_quality_flag` | STRING | NULLABLE | Quality flag |

**Partitioning**: By `data_timestamp` (daily)
**Clustering**: `latitude`, `longitude`, `pressure_level`

### raw_openaq

Air quality measurements from OpenAQ.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `source_id` | STRING | REQUIRED | "openaq" |
| `ingestion_timestamp` | TIMESTAMP | REQUIRED | Ingestion time |
| `data_timestamp` | TIMESTAMP | REQUIRED | Measurement time |
| `latitude` | FLOAT64 | REQUIRED | Station latitude |
| `longitude` | FLOAT64 | REQUIRED | Station longitude |
| `location_name` | STRING | REQUIRED | Station name |
| `city` | STRING | NULLABLE | City name |
| `country` | STRING | REQUIRED | Country code |
| `pm25` | FLOAT64 | NULLABLE | PM2.5 (µg/m³) |
| `pm10` | FLOAT64 | NULLABLE | PM10 (µg/m³) |
| `o3` | FLOAT64 | NULLABLE | Ozone (µg/m³) |
| `no2` | FLOAT64 | NULLABLE | NO2 (µg/m³) |
| `so2` | FLOAT64 | NULLABLE | SO2 (µg/m³) |
| `co` | FLOAT64 | NULLABLE | CO (µg/m³) |
| `data_quality_flag` | STRING | NULLABLE | Quality flag |

**Partitioning**: By `data_timestamp` (hourly)
**Clustering**: `country`, `city`

---

## Staging Layer Schemas

### staging_weather_observations

Unified weather observations from multiple sources.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `observation_id` | STRING | REQUIRED | Unique observation ID |
| `source_id` | STRING | REQUIRED | Original data source |
| `timestamp` | TIMESTAMP | REQUIRED | Observation time (UTC) |
| `latitude` | FLOAT64 | REQUIRED | Location latitude |
| `longitude` | FLOAT64 | REQUIRED | Location longitude |
| `location_name` | STRING | NULLABLE | Location name |
| `temperature_celsius` | FLOAT64 | NULLABLE | Temperature (°C) |
| `precipitation_mm` | FLOAT64 | NULLABLE | Precipitation (mm) |
| `wind_speed_ms` | FLOAT64 | NULLABLE | Wind speed (m/s) |
| `humidity_percent` | FLOAT64 | NULLABLE | Relative humidity (%) |
| `pressure_hpa` | FLOAT64 | NULLABLE | Atmospheric pressure (hPa) |
| `quality_score` | FLOAT64 | NULLABLE | Data quality score (0-1) |
| `processing_timestamp` | TIMESTAMP | REQUIRED | Processing time |

**Partitioning**: By `timestamp` (daily)
**Clustering**: `source_id`, `location_name`

### staging_climate_projections

Climate model projections from various sources.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `projection_id` | STRING | REQUIRED | Unique projection ID |
| `source_id` | STRING | REQUIRED | Model source |
| `model` | STRING | REQUIRED | Climate model name |
| `scenario` | STRING | REQUIRED | Emission scenario (RCP, SSP) |
| `year` | INTEGER | REQUIRED | Projection year |
| `month` | INTEGER | NULLABLE | Month (1-12) |
| `latitude` | FLOAT64 | REQUIRED | Grid latitude |
| `longitude` | FLOAT64 | REQUIRED | Grid longitude |
| `region` | STRING | NULLABLE | Geographic region |
| `variable` | STRING | REQUIRED | Climate variable |
| `value` | FLOAT64 | REQUIRED | Projected value |
| `unit` | STRING | REQUIRED | Unit of measurement |
| `processing_timestamp` | TIMESTAMP | REQUIRED | Processing time |

**Partitioning**: By `year`
**Clustering**: `model`, `scenario`, `variable`

### staging_sea_level

Sea level measurements and trends.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `measurement_id` | STRING | REQUIRED | Unique measurement ID |
| `source_id` | STRING | REQUIRED | Data source |
| `timestamp` | TIMESTAMP | REQUIRED | Measurement time |
| `latitude` | FLOAT64 | REQUIRED | Station latitude |
| `longitude` | FLOAT64 | REQUIRED | Station longitude |
| `station_id` | STRING | REQUIRED | Station identifier |
| `station_name` | STRING | REQUIRED | Station name |
| `water_level_m` | FLOAT64 | REQUIRED | Water level (m) |
| `water_temp_celsius` | FLOAT64 | NULLABLE | Water temperature (°C) |
| `datum` | STRING | REQUIRED | Vertical datum |
| `quality_score` | FLOAT64 | NULLABLE | Quality score (0-1) |
| `processing_timestamp` | TIMESTAMP | REQUIRED | Processing time |

**Partitioning**: By `timestamp` (daily)
**Clustering**: `station_id`

---

## Analytics Layer Schemas

### analytics_time_series_weather

Time series data optimized for ML models.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `series_id` | STRING | REQUIRED | Time series identifier |
| `location_id` | STRING | REQUIRED | Location identifier |
| `latitude` | FLOAT64 | REQUIRED | Location latitude |
| `longitude` | FLOAT64 | REQUIRED | Location longitude |
| `timestamp` | TIMESTAMP | REQUIRED | Observation time |
| `temperature_celsius` | FLOAT64 | NULLABLE | Temperature |
| `precipitation_mm` | FLOAT64 | NULLABLE | Precipitation |
| `wind_speed_ms` | FLOAT64 | NULLABLE | Wind speed |
| `humidity_percent` | FLOAT64 | NULLABLE | Humidity |
| `pressure_hpa` | FLOAT64 | NULLABLE | Pressure |
| `rolling_7d_temp_avg` | FLOAT64 | NULLABLE | 7-day temp average |
| `rolling_30d_temp_avg` | FLOAT64 | NULLABLE | 30-day temp average |
| `temp_anomaly` | FLOAT64 | NULLABLE | Temperature anomaly |
| `is_extreme_event` | BOOLEAN | NULLABLE | Extreme weather flag |

**Partitioning**: By `timestamp` (daily)
**Clustering**: `location_id`

### analytics_spatial_climate_grid

Gridded climate data for spatial analysis.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `grid_id` | STRING | REQUIRED | Grid cell identifier |
| `latitude` | FLOAT64 | REQUIRED | Grid center latitude |
| `longitude` | FLOAT64 | REQUIRED | Grid center longitude |
| `year` | INTEGER | REQUIRED | Year |
| `month` | INTEGER | REQUIRED | Month |
| `avg_temperature` | FLOAT64 | NULLABLE | Monthly avg temperature |
| `total_precipitation` | FLOAT64 | NULLABLE | Monthly total precipitation |
| `avg_wind_speed` | FLOAT64 | NULLABLE | Monthly avg wind speed |
| `avg_humidity` | FLOAT64 | NULLABLE | Monthly avg humidity |
| `data_completeness` | FLOAT64 | NULLABLE | % of days with data |
| `source_count` | INTEGER | NULLABLE | Number of contributing sources |

**Partitioning**: By year/month
**Clustering**: `latitude`, `longitude`

### analytics_climate_indicators

Aggregated climate indicators for trend analysis.

| Field | Type | Mode | Description |
|-------|------|------|-------------|
| `indicator_id` | STRING | REQUIRED | Indicator identifier |
| `indicator_name` | STRING | REQUIRED | Indicator name |
| `region` | STRING | REQUIRED | Geographic region |
| `year` | INTEGER | REQUIRED | Year |
| `value` | FLOAT64 | REQUIRED | Indicator value |
| `unit` | STRING | REQUIRED | Unit |
| `baseline_value` | FLOAT64 | NULLABLE | Historical baseline |
| `percent_change` | FLOAT64 | NULLABLE | Change from baseline (%) |
| `trend` | STRING | NULLABLE | Trend direction |
| `confidence_level` | FLOAT64 | NULLABLE | Confidence (0-1) |

**Partitioning**: By `year`
**Clustering**: `region`, `indicator_name`

---

## Data Quality Flags

Standard quality flags used across all tables:

| Flag | Description |
|------|-------------|
| `GOOD` | Data passed all validation checks |
| `FAIR` | Data has minor issues but is usable |
| `POOR` | Data has significant quality concerns |
| `UNKNOWN` | Quality cannot be determined |
| `MISSING` | Data is missing or null |
| `OUTLIER` | Data identified as statistical outlier |

---

## Partitioning Strategy

- **Time-series data**: Partition by timestamp (daily or monthly)
- **Reduces query costs**: Only scans relevant partitions
- **Improves performance**: Faster queries on date ranges
- **Automatic pruning**: BigQuery automatically prunes irrelevant partitions

## Clustering Strategy

- **Frequently filtered columns**: Use for WHERE clauses
- **Join keys**: Optimize table joins
- **Up to 4 columns**: Ordered by filter frequency
- **Reduces bytes scanned**: Improves query performance and cost

---

## Best Practices

1. **Always partition large tables** by timestamp
2. **Use clustering** on frequently filtered columns
3. **Include data quality flags** for filtering
4. **Maintain consistent naming** across tables
5. **Document all schema changes**
6. **Version schemas** in the `schemas/` directory
7. **Test queries** on small date ranges first
8. **Monitor costs** using BigQuery console

---

**Last Updated**: 2025-11-14
**Version**: 1.0
