variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "network" { type = string }
variable "subnetwork" { type = string }
variable "service_account_email" { type = string }
variable "node_count" { type = number }
variable "machine_type" { type = string }
variable "disk_size_gb" { type = number }
variable "airflow_config_overrides" {
  type    = map(string)
  default = {}
}
variable "pypi_packages" {
  type    = map(string)
  default = {}
}
