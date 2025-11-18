# BigQuery tables for climate data sources
# This module creates tables for ingesting climate data from various public sources

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "dataset_id" {
  description = "BigQuery dataset ID for climate data"
  type        = string
  default     = "climate_data"
}

variable "location" {
  description = "BigQuery location"
  type        = string
  default     = "US"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "delete_contents_on_destroy" {
  description = "Whether to delete table contents on destroy (false for prod)"
  type        = bool
  default     = true
}

# Create the climate_data dataset
resource "google_bigquery_dataset" "climate_data" {
  dataset_id                 = var.dataset_id
  project                    = var.project_id
  location                   = var.location
  description                = "Climate data warehouse containing temperature, emissions, and greenhouse gas measurements"
  delete_contents_on_destroy = var.delete_contents_on_destroy

  labels = merge(var.labels, {
    data_source = "climate_apis"
    zone        = "raw"
  })
}

# =============================================================================
# GLOBAL WARMING API TABLES
# =============================================================================

# Global Warming API - Temperature anomalies
resource "google_bigquery_table" "raw_gw_temperature" {
  dataset_id          = google_bigquery_dataset.climate_data.dataset_id
  table_id            = "raw_gw_temperature"
  project             = var.project_id
  deletion_protection = false

  description = "Global temperature anomalies from Global Warming API (https://global-warming.org/api/temperature-api)"

  labels = merge(var.labels, {
    source      = "global_warming_api"
    data_type   = "temperature"
    update_freq = "monthly"
  })

  time_partitioning {
    type  = "DAY"
    field = "measurement_date"
  }

  clustering = ["ingestion_timestamp"]

  schema = jsonencode([
    {
      name        = "record_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique identifier for the record (MD5 hash of endpoint + time)"
    },
    {
      name        = "measurement_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Date of the temperature measurement"
    },
    {
      name        = "land"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Land temperature anomaly in Celsius"
    },
    {
      name        = "station"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Station identifier"
    },
    {
      name        = "time"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Original time string from API"
    },
    {
      name        = "ingestion_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when data was ingested into BigQuery"
    },
    {
      name        = "source_file"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source API URL"
    }
  ])
}

# Global Warming API - CO2 concentrations
resource "google_bigquery_table" "raw_gw_co2" {
  dataset_id          = google_bigquery_dataset.climate_data.dataset_id
  table_id            = "raw_gw_co2"
  project             = var.project_id
  deletion_protection = false

  description = "CO2 atmospheric concentrations from Global Warming API (https://global-warming.org/api/co2-api)"

  labels = merge(var.labels, {
    source      = "global_warming_api"
    data_type   = "co2"
    update_freq = "daily"
  })

  time_partitioning {
    type  = "DAY"
    field = "measurement_date"
  }

  clustering = ["ingestion_timestamp"]

  schema = jsonencode([
    {
      name        = "record_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique identifier for the record"
    },
    {
      name        = "measurement_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Date of the CO2 measurement"
    },
    {
      name        = "cycle"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "CO2 concentration with seasonal cycle (ppm)"
    },
    {
      name        = "trend"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Deseasonalized CO2 trend (ppm)"
    },
    {
      name        = "ingestion_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when data was ingested into BigQuery"
    },
    {
      name        = "source_file"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source API URL"
    }
  ])
}

# Global Warming API - Methane concentrations
resource "google_bigquery_table" "raw_gw_methane" {
  dataset_id          = google_bigquery_dataset.climate_data.dataset_id
  table_id            = "raw_gw_methane"
  project             = var.project_id
  deletion_protection = false

  description = "Methane atmospheric concentrations from Global Warming API (https://global-warming.org/api/methane-api)"

  labels = merge(var.labels, {
    source      = "global_warming_api"
    data_type   = "methane"
    update_freq = "monthly"
  })

  time_partitioning {
    type  = "DAY"
    field = "measurement_date"
  }

  clustering = ["ingestion_timestamp"]

  schema = jsonencode([
    {
      name        = "record_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique identifier for the record"
    },
    {
      name        = "measurement_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Date of the methane measurement"
    },
    {
      name        = "average"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Atmospheric CH4 concentration (ppb)"
    },
    {
      name        = "trend"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Deseasonalized CH4 trend (ppb)"
    },
    {
      name        = "ingestion_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when data was ingested into BigQuery"
    },
    {
      name        = "source_file"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source API URL"
    }
  ])
}

# Global Warming API - Nitrous oxide concentrations
resource "google_bigquery_table" "raw_gw_nitrous_oxide" {
  dataset_id          = google_bigquery_dataset.climate_data.dataset_id
  table_id            = "raw_gw_nitrous_oxide"
  project             = var.project_id
  deletion_protection = false

  description = "Nitrous oxide atmospheric concentrations from Global Warming API (https://global-warming.org/api/nitrous-oxide-api)"

  labels = merge(var.labels, {
    source      = "global_warming_api"
    data_type   = "nitrous_oxide"
    update_freq = "monthly"
  })

  time_partitioning {
    type  = "DAY"
    field = "measurement_date"
  }

  clustering = ["ingestion_timestamp"]

  schema = jsonencode([
    {
      name        = "record_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique identifier for the record"
    },
    {
      name        = "measurement_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Date of the N2O measurement"
    },
    {
      name        = "average"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Atmospheric N2O concentration (ppb)"
    },
    {
      name        = "trend"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Deseasonalized N2O trend (ppb)"
    },
    {
      name        = "ingestion_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when data was ingested into BigQuery"
    },
    {
      name        = "source_file"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source API URL"
    }
  ])
}

# =============================================================================
# NASA GISTEMP v4 TABLES
# =============================================================================

# NASA GISTEMP - Global, Northern, and Southern Hemisphere monthly temperature anomalies
resource "google_bigquery_table" "raw_gistemp_global" {
  dataset_id          = google_bigquery_dataset.climate_data.dataset_id
  table_id            = "raw_gistemp_global"
  project             = var.project_id
  deletion_protection = false

  description = "NASA GISTEMP v4 - Monthly temperature anomalies for Global, Northern, and Southern Hemispheres (https://data.giss.nasa.gov/gistemp/)"

  labels = merge(var.labels, {
    source      = "nasa_gistemp"
    data_type   = "temperature"
    update_freq = "monthly"
  })

  time_partitioning {
    type  = "DAY"
    field = "measurement_date"
  }

  clustering = ["hemisphere", "year"]

  schema = jsonencode([
    {
      name        = "year"
      type        = "INT64"
      mode        = "REQUIRED"
      description = "Year of measurement"
    },
    {
      name        = "month"
      type        = "INT64"
      mode        = "REQUIRED"
      description = "Month of measurement (1-12)"
    },
    {
      name        = "temperature_anomaly"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Temperature anomaly in Celsius relative to 1951-1980 baseline"
    },
    {
      name        = "measurement_date"
      type        = "DATE"
      mode        = "REQUIRED"
      description = "Date of measurement (first day of month)"
    },
    {
      name        = "record_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique identifier for the record"
    },
    {
      name        = "ingestion_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when data was ingested into BigQuery"
    },
    {
      name        = "source_file"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source CSV file URL"
    },
    {
      name        = "hemisphere"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Hemisphere identifier: Global, Northern, or Southern"
    }
  ])
}

# NASA GISTEMP - Zonal annual means
resource "google_bigquery_table" "raw_gistemp_zonal" {
  dataset_id          = google_bigquery_dataset.climate_data.dataset_id
  table_id            = "raw_gistemp_zonal"
  project             = var.project_id
  deletion_protection = false

  description = "NASA GISTEMP v4 - Zonal annual temperature means (https://data.giss.nasa.gov/gistemp/tabledata_v4/ZonAnn.Ts+dSST.csv)"

  labels = merge(var.labels, {
    source      = "nasa_gistemp"
    data_type   = "temperature_zonal"
    update_freq = "monthly"
  })

  clustering = ["zone", "year"]

  schema = jsonencode([
    {
      name        = "year"
      type        = "INT64"
      mode        = "REQUIRED"
      description = "Year of measurement"
    },
    {
      name        = "zone"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Zone identifier (e.g., Glob, NHem, SHem, 24N-90N, etc.)"
    },
    {
      name        = "temperature_anomaly"
      type        = "FLOAT64"
      mode        = "NULLABLE"
      description = "Annual temperature anomaly in Celsius"
    },
    {
      name        = "record_id"
      type        = "STRING"
      mode        = "REQUIRED"
      description = "Unique identifier for the record"
    },
    {
      name        = "ingestion_timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Timestamp when data was ingested into BigQuery"
    },
    {
      name        = "source_file"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Source CSV file URL"
    }
  ])
}
