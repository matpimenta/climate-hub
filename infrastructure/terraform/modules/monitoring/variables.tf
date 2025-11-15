variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "notification_channels" {
  type    = list(string)
  default = []
}
variable "enable_pipeline_failure_alerts" {
  type    = bool
  default = true
}
variable "enable_data_freshness_alerts" {
  type    = bool
  default = true
}
variable "enable_cost_alerts" {
  type    = bool
  default = true
}
variable "enable_security_alerts" {
  type    = bool
  default = true
}
variable "daily_cost_threshold" { type = number }
variable "data_freshness_sla_minutes" { type = number }
