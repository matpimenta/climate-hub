variable "project_id" { type = string }
variable "region" { type = string }
variable "environment" { type = string }
variable "name_prefix" { type = string }
variable "labels" {
  type    = map(string)
  default = {}
}
variable "feature_store_config" { type = any }
variable "encryption_key" {
  type    = string
  default = null
}
