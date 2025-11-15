variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "service_account_email" { type = string }
variable "vpc_connector_id" { type = string }
variable "allow_unauthenticated" {
  type    = bool
  default = false
}
