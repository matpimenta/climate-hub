# Module: networking
# Purpose: VPC, subnets, firewall rules, and VPC connectors for the data platform

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = "${var.name_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC for ${var.environment} data platform"

  # Delete default routes on destroy
  delete_default_routes_on_create = false
}

# Subnets for different components
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "${var.name_prefix}-subnet-${each.key}"
  project       = var.project_id
  region        = each.value.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = each.value.cidr
  description   = each.value.description

  # Enable Private Google Access for API calls without public IPs
  private_ip_google_access = var.enable_private_google_access

  # Enable VPC Flow Logs for network monitoring
  dynamic "log_config" {
    for_each = var.enable_flow_logs ? [1] : []
    content {
      aggregation_interval = "INTERVAL_5_SEC"
      flow_sampling        = 0.5 # Sample 50% of traffic
      metadata             = "INCLUDE_ALL_METADATA"
    }
  }

  # Secondary IP ranges for GKE (if needed in future)
  # secondary_ip_range {
  #   range_name    = "pods"
  #   ip_cidr_range = "10.1.0.0/16"
  # }
  # secondary_ip_range {
  #   range_name    = "services"
  #   ip_cidr_range = "10.2.0.0/16"
  # }
}

# Cloud Router for NAT Gateway
resource "google_compute_router" "router" {
  name    = "${var.name_prefix}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT for outbound internet access from private IPs
resource "google_compute_router_nat" "nat" {
  name    = "${var.name_prefix}-nat"
  project = var.project_id
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Firewall rule: Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.name_prefix}-allow-internal"
  project = var.project_id
  network = google_compute_network.vpc.name

  description = "Allow internal communication between resources"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.vpc_cidr]
  priority      = 1000
}

# Firewall rule: Allow SSH for debugging (restricted to IAP)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${var.name_prefix}-allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.vpc.name

  description = "Allow SSH via Identity-Aware Proxy"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]
  priority      = 1000
}

# Firewall rule: Deny all ingress by default
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.name_prefix}-deny-all-ingress"
  project = var.project_id
  network = google_compute_network.vpc.name

  description = "Deny all ingress traffic by default"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534 # Lowest priority
}

# VPC Serverless Connector for Cloud Functions and Cloud Run
resource "google_vpc_access_connector" "connector" {
  name    = "${var.name_prefix}-vpc-connector"
  project = var.project_id
  region  = var.region

  network = google_compute_network.vpc.name

  # IP range for the connector (must not overlap with subnets)
  ip_cidr_range = var.vpc_connector_cidr

  # Machine type for connector instances
  machine_type = var.vpc_connector_machine_type

  # Number of instances (2-10)
  min_instances = var.vpc_connector_min_instances
  max_instances = var.vpc_connector_max_instances
}

# Private Service Connection for managed services (Composer, Cloud SQL, etc.)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.name_prefix}-private-ip"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# DNS Zone for private Google APIs (optional but recommended)
resource "google_dns_managed_zone" "private_google_apis" {
  count = var.enable_private_google_apis_dns ? 1 : 0

  name        = "${var.name_prefix}-google-apis"
  project     = var.project_id
  dns_name    = "googleapis.com."
  description = "Private DNS zone for Google APIs"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

# DNS record for all Google APIs
resource "google_dns_record_set" "private_googleapis" {
  count = var.enable_private_google_apis_dns ? 1 : 0

  name         = "*.googleapis.com."
  project      = var.project_id
  managed_zone = google_dns_managed_zone.private_google_apis[0].name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}
