# Outputs for climate data BigQuery module

output "dataset_id" {
  description = "The ID of the climate data dataset"
  value       = google_bigquery_dataset.climate_data.dataset_id
}

output "dataset_full_id" {
  description = "The full ID of the climate data dataset (project:dataset)"
  value       = "${var.project_id}:${google_bigquery_dataset.climate_data.dataset_id}"
}

output "table_ids" {
  description = "Map of table names to their full IDs"
  value = {
    raw_gw_temperature    = "${var.project_id}.${google_bigquery_dataset.climate_data.dataset_id}.${google_bigquery_table.raw_gw_temperature.table_id}"
    raw_gw_co2            = "${var.project_id}.${google_bigquery_dataset.climate_data.dataset_id}.${google_bigquery_table.raw_gw_co2.table_id}"
    raw_gw_methane        = "${var.project_id}.${google_bigquery_dataset.climate_data.dataset_id}.${google_bigquery_table.raw_gw_methane.table_id}"
    raw_gw_nitrous_oxide  = "${var.project_id}.${google_bigquery_dataset.climate_data.dataset_id}.${google_bigquery_table.raw_gw_nitrous_oxide.table_id}"
    raw_gistemp_global    = "${var.project_id}.${google_bigquery_dataset.climate_data.dataset_id}.${google_bigquery_table.raw_gistemp_global.table_id}"
    raw_gistemp_zonal     = "${var.project_id}.${google_bigquery_dataset.climate_data.dataset_id}.${google_bigquery_table.raw_gistemp_zonal.table_id}"
  }
}
