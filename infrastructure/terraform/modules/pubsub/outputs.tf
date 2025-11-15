output "topics" {
  description = "Map of Pub/Sub topic resources"
  value       = google_pubsub_topic.topics
}

output "subscriptions" {
  description = "Map of Pub/Sub subscription resources"
  value       = google_pubsub_subscription.subscriptions
}

output "topic_names" {
  description = "Map of topic names"
  value = {
    for k, v in google_pubsub_topic.topics : k => v.name
  }
}

output "subscription_names" {
  description = "Map of subscription names"
  value = {
    for k, v in google_pubsub_subscription.subscriptions : k => v.name
  }
}
