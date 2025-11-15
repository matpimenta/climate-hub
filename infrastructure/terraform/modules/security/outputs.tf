output "service_accounts" {
  description = "Map of service account resources"
  value       = google_service_account.service_accounts
}

output "service_account_emails" {
  description = "Map of service account email addresses"
  value = {
    for k, v in google_service_account.service_accounts : k => v.email
  }
}

output "kms_keyring_id" {
  description = "KMS key ring ID"
  value       = var.enable_cmek ? google_kms_key_ring.keyring[0].id : null
}

output "kms_crypto_keys" {
  description = "Map of KMS crypto keys"
  value       = google_kms_crypto_key.keys
}
