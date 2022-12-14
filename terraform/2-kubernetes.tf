resource "google_container_cluster" "primary" {
  name     = "${var.gke_primary_cluster_name}-${random_string.kubernetes_suffix.result}"
  location = var.default_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.kubernetes_network.self_link
  subnetwork = google_compute_subnetwork.kubernetes_subnet["gke-uscentral1-primary"].self_link


  ip_allocation_policy {
    cluster_ipv4_cidr_block=""
    # cluster_secondary_range_name  = google_compute_subnetwork.kubernetes_subnet["gke-uscentral1-primary"].secondary_ip_range.0.range_name
    services_ipv4_cidr_block=""
    # services_secondary_range_name = google_compute_subnetwork.kubernetes_subnet["gke-uscentral1-primary"].secondary_ip_range.1.range_name
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name     = "${google_container_cluster.primary.name}-node-pool"
  location = var.default_region
  cluster  = google_container_cluster.primary.name

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.gke_nodepool_machine_type
    disk_size_gb = 50
    disk_type    = "pd-balanced"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = "development"
    }

    tags = ["gke-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Remote cluster
resource "google_container_cluster" "secondary" {
  name     = "${var.gke_secondary_cluster_name}-${random_string.kubernetes_suffix.result}"
  location = var.backup_region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.kubernetes_network.self_link
  subnetwork = google_compute_subnetwork.kubernetes_subnet["gke-uswest4-secondary"].self_link

  ip_allocation_policy {
    cluster_ipv4_cidr_block=""
    # cluster_secondary_range_name  = google_compute_subnetwork.kubernetes_subnet["gke-uswest4-secondary"].secondary_ip_range.0.range_name
    services_ipv4_cidr_block=""
    # services_secondary_range_name = google_compute_subnetwork.kubernetes_subnet["gke-uswest4-secondary"].secondary_ip_range.1.range_name
  }
}

resource "google_container_node_pool" "secondary_nodes" {
  name     = "${google_container_cluster.secondary.name}-node-pool"
  location = var.backup_region
  cluster  = google_container_cluster.secondary.name

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.gke_nodepool_machine_type
    disk_size_gb = 50
    disk_type    = "pd-balanced"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = "development"
    }

    tags = ["gke-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}