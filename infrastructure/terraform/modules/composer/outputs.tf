output "environment_name" { value = "${var.name_prefix}-composer" }
output "airflow_uri" { value = "https://airflow.example.com" }
output "gcs_bucket" { value = "composer-bucket" }
output "dag_gcs_prefix" { value = "dags" }
