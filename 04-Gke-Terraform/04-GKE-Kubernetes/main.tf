data "google_compute_network" "existing_vpc" {
  name = var.network_name
}

resource "google_compute_subnetwork" "securebank_gke_subnet" {

  name          = var.gke_subnet_name
  ip_cidr_range = var.gke_subnet_cidr

  region  = var.region
  network = data.google_compute_network.existing_vpc.id

  secondary_ip_range {
    range_name    = "securebank-pods-range"
    ip_cidr_range = var.pods_secondary_range
  }

  secondary_ip_range {
    range_name    = "securebank-services-range"
    ip_cidr_range = var.services_secondary_range
  }
}

resource "google_container_cluster" "securebank_gke" {

  name     = var.cluster_name
  location = var.zone

  network    = data.google_compute_network.existing_vpc.name
  subnetwork = google_compute_subnetwork.securebank_gke_subnet.name

  remove_default_node_pool = true

  initial_node_count = 1

  networking_mode = "VPC_NATIVE"

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "securebank-pods-range"
    services_secondary_range_name = "securebank-services-range"
  }

  deletion_protection = false
}

resource "google_container_node_pool" "securebank_nodepool" {

  name     = "securebank-nodepool"
  cluster  = google_container_cluster.securebank_gke.name
  location = var.zone

  node_count = var.node_count

  node_config {

    machine_type = var.machine_type

    disk_size_gb = 50

    disk_type = "pd-balanced"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {

      application = "securebank"

      environment = "dev"

      managed_by = "terraform"
    }

    tags = [
      "securebank",
      "gke-node"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}