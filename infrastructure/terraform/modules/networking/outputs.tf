output "vpc_network" {
  description = "VPC network resource"
  value       = google_compute_network.vpc
}

output "subnets" {
  description = "Subnet resources"
  value       = google_compute_subnetwork.subnets
}

output "vpc_connector_id" {
  description = "VPC Serverless Connector ID"
  value       = google_vpc_access_connector.connector.id
}

output "vpc_connector_name" {
  description = "VPC Serverless Connector name"
  value       = google_vpc_access_connector.connector.name
}

output "nat_ips" {
  description = "NAT gateway IP addresses"
  value       = google_compute_router_nat.nat.nat_ips
}
