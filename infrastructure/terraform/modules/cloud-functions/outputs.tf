output "config" {
  value = {
    service_account = var.service_account_email
    vpc_connector   = var.vpc_connector
  }
}
