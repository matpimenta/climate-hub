variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "service_account_email" { type = string }
variable "source_bucket" { type = string }
variable "vpc_connector" { type = string }
