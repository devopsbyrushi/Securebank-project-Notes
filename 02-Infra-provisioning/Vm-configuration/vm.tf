data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

########################################
# Jenkins VM
########################################

resource "google_compute_instance" "jenkins" {
  name         = "bankingproject2027-jenkins-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["jenkins"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }
}

########################################
# Docker VM
########################################

resource "google_compute_instance" "docker" {
  name         = "bankingproject2027-docker-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["docker"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }
}

########################################
# SonarQube VM
########################################

resource "google_compute_instance" "sonarqube" {
  name         = "bankingproject2027-sonarqube-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["sonarqube"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }
}

########################################
# Monitoring VM
########################################

resource "google_compute_instance" "monitoring" {
  name         = "bankingproject2027-monitoring-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["monitoring"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = 30
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {}
  }
}