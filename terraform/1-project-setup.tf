# Enabling APIs for the project
resource "google_project_service" "project" {
  for_each = var.enabled_services_set
  project  = var.bootstrap_project_id
  service  = each.key

  timeouts {
    create = "10m"
    update = "10m"
    read   = "10m"
    delete = "10m"
  }

  disable_dependent_services = false
}

# Create custom VPC
resource "google_compute_network" "kubernetes_network" {
  project                 = var.bootstrap_project_id
  name                    = "kubernetes-network"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.project]
}

resource "google_compute_subnetwork" "kubernetes_subnet" {
  for_each      = var.kubernetes_subnet_cidr
  project       = var.bootstrap_project_id
  name          = each.key
  ip_cidr_range = each.value.cidr_block
  region        = each.value.region
  network       = google_compute_network.kubernetes_network.self_link
  secondary_ip_range {
    range_name    = each.value.secondary_pod_name
    ip_cidr_range = each.value.secondary_pod_cidr_block
  }
  secondary_ip_range {
    range_name    = each.value.secondary_service_name
    ip_cidr_range = each.value.secondary_service_cidr_block
  }
  depends_on = [google_project_service.project]
}

# Set up firewall rules
resource "google_compute_firewall" "allow_ingress_internet" {
  name      = "allow-ingress-internet"
  project   = var.bootstrap_project_id
  network   = google_compute_network.kubernetes_network.self_link
  direction = "INGRESS"
  allow {
    protocol = "TCP"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}