output "cluster_name" {
  value = google_container_cluster.securebank_gke.name
}

output "cluster_endpoint" {
  value = google_container_cluster.securebank_gke.endpoint
}

output "cluster_location" {
  value = google_container_cluster.securebank_gke.location
}

output "node_pool_name" {
  value = google_container_node_pool.securebank_nodepool.name
}

output "gke_subnet_name" {
  value = google_compute_subnetwork.securebank_gke_subnet.name
}