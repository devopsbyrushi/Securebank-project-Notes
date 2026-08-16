output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "jenkins_public_ip" {
  value = google_compute_instance.jenkins.network_interface[0].access_config[0].nat_ip
}

output "docker_public_ip" {
  value = google_compute_instance.docker.network_interface[0].access_config[0].nat_ip
}

output "sonarqube_public_ip" {
  value = google_compute_instance.sonarqube.network_interface[0].access_config[0].nat_ip
}

output "monitoring_public_ip" {
  value = google_compute_instance.monitoring.network_interface[0].access_config[0].nat_ip
}

output "jenkins_private_ip" {
  value = google_compute_instance.jenkins.network_interface[0].network_ip
}

output "docker_private_ip" {
  value = google_compute_instance.docker.network_interface[0].network_ip
}

output "sonarqube_private_ip" {
  value = google_compute_instance.sonarqube.network_interface[0].network_ip
}

output "monitoring_private_ip" {
  value = google_compute_instance.monitoring.network_interface[0].network_ip
}