resource "google_compute_firewall" "bankingproject2027-firewall" {
  name    = "bankingproject2027-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"

    ports = [
      "22",
      "80",
      "443",
      "8080",
      "8081",
      "9000",
      "3000",
      "9100",
      "9090"
    ]
  }

  source_ranges = ["0.0.0.0/0"]
}