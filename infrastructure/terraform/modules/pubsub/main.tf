# Module: pubsub
# Purpose: Pub/Sub topics and subscriptions for data ingestion

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Pub/Sub Topics
resource "google_pubsub_topic" "topics" {
  for_each = var.topics

  name    = "${var.name_prefix}-${each.key}"
  project = var.project_id

  labels = merge(
    var.labels,
    {
      topic_type = each.key
    }
  )

  message_retention_duration = each.value.message_retention_duration

  # Encryption
  dynamic "message_storage_policy" {
    for_each = var.encryption_key != null ? [1] : []
    content {
      allowed_persistence_regions = [var.region]
    }
  }
}

# Pub/Sub Subscriptions
resource "google_pubsub_subscription" "subscriptions" {
  for_each = var.subscriptions

  name    = "${var.name_prefix}-${each.key}"
  project = var.project_id
  topic   = google_pubsub_topic.topics[each.value.topic].name

  ack_deadline_seconds       = each.value.ack_deadline_seconds
  message_retention_duration = each.value.message_retention_duration
  retain_acked_messages      = each.value.retain_acked_messages
  enable_exactly_once_delivery = each.value.enable_exactly_once_delivery

  # Dead letter policy
  dynamic "dead_letter_policy" {
    for_each = each.value.dead_letter_topic != null ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.topics[each.value.dead_letter_topic].id
      max_delivery_attempts = each.value.max_delivery_attempts
    }
  }

  # Retry policy
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  labels = var.labels
}

# Grant Dataflow permission to publish to topics
resource "google_pubsub_topic_iam_member" "dataflow_publisher" {
  for_each = toset(keys(google_pubsub_topic.topics))

  project = var.project_id
  topic   = google_pubsub_topic.topics[each.key].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${var.dataflow_service_account}"
}

# Grant Dataflow permission to subscribe
resource "google_pubsub_subscription_iam_member" "dataflow_subscriber" {
  for_each = toset(keys(google_pubsub_subscription.subscriptions))

  project      = var.project_id
  subscription = google_pubsub_subscription.subscriptions[each.key].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.dataflow_service_account}"
}
