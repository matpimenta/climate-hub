variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "backend_service_url" { type = string }
variable "oauth_issuer" { type = string }
variable "oauth_audiences" { type = list(string) }
variable "rate_limit_requests_per_minute" { type = number }
