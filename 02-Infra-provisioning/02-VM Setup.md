# 🚀 GCP Virtual Machine Deployment Using Terraform & Visual Studio Code

## Executive Summary

### Project Objective

Provision multiple Google Cloud Platform (GCP) Virtual Machines using Infrastructure as Code (IaC) with Terraform.

### Business Use Case

This infrastructure provides dedicated servers for:

* Jenkins CI/CD Server
* Docker Application Server
* SonarQube Code Quality Server
* Prometheus & Grafana Monitoring Server

The deployment is fully automated and reproducible, reducing manual effort and configuration errors.

### Solution Overview

Terraform will create:

* Custom VPC Network
* Custom Subnet
* Firewall Rules
* Jenkins VM
* Docker VM
* SonarQube VM
* Monitoring VM

### Expected Outcome

After successful deployment:

* Four Ubuntu 24.04 LTS Virtual Machines will be created.
* All required ports will be accessible.
* Infrastructure can be recreated anytime using Terraform.
* Resources will be deployed in:

| Parameter    | Value         |
| ------------ | ------------- |
| Region       | asia-south1   |
| Zone         | asia-south1-c |
| Machine Type | e2-standard-2 |

---

# Architecture Diagram

```text
Google Cloud Platform
        │
        ▼
     Custom VPC
        │
        ▼
     Subnet
        │
 ┌──────┼───────────────┬───────────────┬───────────────┐
 ▼      ▼               ▼               ▼
Jenkins Docker      SonarQube      Monitoring
 VM       VM            VM              VM
```

---

# Prerequisites

Before starting, ensure the following tools are installed:

### 1. Visual Studio Code

Download:

https://code.visualstudio.com

### 2. Terraform

Verify installation:

```bash
terraform -version
```

### 3. Google Cloud SDK

Verify installation:

```bash
gcloud version
```

### 4. GCP Project

Create a project:

```text
bankingproject2027
```

### 5. Service Account Key

Generate:

```text
terraform-key.json
```

Store it in the Terraform project folder.

---

# Project Structure

```text
terraform-gcp-vm/
│
├── provider.tf
├── versions.tf
├── variables.tf
├── terraform.tfvars
├── network.tf
├── firewall.tf
├── vm.tf
├── terraform-key.json
```

---

# Step 1: Open Project in Visual Studio Code

Launch VS Code.

Open Terminal:

```bash
Terminal → New Terminal
```

Navigate to project directory:

```bash
cd terraform-gcp-vm
```

---

# Step 2: Configure Provider

## provider.tf

```hcl
provider "google" {
  credentials = file("terraform-key.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}
```

---

# Step 3: Configure Terraform Version

## versions.tf

```hcl
terraform {
  required_version = ">= 1.8.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
```

---

# Step 4: Configure Variables

## variables.tf

```hcl
variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  default = "asia-south1"
}

variable "zone" {
  default = "asia-south1-c"
}

variable "project_name" {
  default = "bankingproject2027"
}

variable "network_name" {
  default = "bankingproject2027-vpc"
}

variable "subnet_name" {
  default = "bankingproject2027-subnet"
}

variable "subnet_cidr" {
  default = "10.10.0.0/24"
}

variable "machine_type" {
  default = "e2-standard-2"
}
```

---

# Step 5: Configure Terraform Variables

## terraform.tfvars

```hcl
project_id = "bankingproject2027"

region = "asia-south1"

zone = "asia-south1-c"
```

---

# Step 6: Create VPC Network

## network.tf

```hcl
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}
```

---

# Step 7: Configure Firewall Rules

## firewall.tf

```hcl
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
```

---

# Port Usage Reference

| Port | Purpose       |
| ---- | ------------- |
| 22   | SSH           |
| 80   | HTTP          |
| 443  | HTTPS         |
| 8080 | Jenkins       |
| 8081 | Application   |
| 9000 | SonarQube     |
| 3000 | Grafana       |
| 9090 | Prometheus    |
| 9100 | Node Exporter |

---

# Step 8: Create Virtual Machines

## vm.tf

```hcl
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
```

---

# Step 9: Initialize Terraform

Execute:

```bash
terraform init
```

Expected:

```text
Terraform has been successfully initialized!
```

---

# Step 10: Validate Configuration

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

# Step 11: Review Infrastructure Plan

```bash
terraform plan
```

Terraform displays all resources that will be created.

Expected Resources:

```text
google_compute_network
google_compute_subnetwork
google_compute_firewall

google_compute_instance.jenkins
google_compute_instance.docker
google_compute_instance.sonarqube
google_compute_instance.monitoring
```

---

# Step 12: Deploy Infrastructure

```bash
terraform apply
```

Type:

```text
yes
```

Terraform will create:

* VPC
* Subnet
* Firewall
* Jenkins VM
* Docker VM
* SonarQube VM
* Monitoring VM

---

# Step 13: Verify Deployment

List created VMs:

```bash
gcloud compute instances list
```

Expected:

```text
bankingproject2027-jenkins-vm
bankingproject2027-docker-vm
bankingproject2027-sonarqube-vm
bankingproject2027-monitoring-vm
```

---

# Step 14: Connect to Virtual Machines

## Jenkins VM

```bash
gcloud compute ssh bankingproject2027-jenkins-vm --zone asia-south1-c
```

## Docker VM

```bash
gcloud compute ssh bankingproject2027-docker-vm --zone asia-south1-c
```

## SonarQube VM

```bash
gcloud compute ssh bankingproject2027-sonarqube-vm --zone asia-south1-c
```

## Monitoring VM

```bash
gcloud compute ssh bankingproject2027-monitoring-vm --zone asia-south1-c
```

---

# Terraform Useful Commands

### View State

```bash
terraform state list
```

### Refresh State

```bash
terraform refresh
```

### Show Infrastructure

```bash
terraform show
```

### Destroy Infrastructure

```bash
terraform destroy
```

---

# Deployment Workflow

```text
Developer
   │
   ▼
Visual Studio Code
   │
   ▼
Terraform Configuration
   │
   ▼
terraform init
   │
   ▼
terraform validate
   │
   ▼
terraform plan
   │
   ▼
terraform apply
   │
   ▼
Google Cloud Platform
   │
   ▼
VPC + Subnet + Firewall
   │
   ▼
Jenkins VM
Docker VM
SonarQube VM
Monitoring VM
```

---

# Final Outcome

Successfully provisioned a production-ready Google Cloud Infrastructure using Terraform in Visual Studio Code.

Infrastructure Includes:

* 1 Custom VPC
* 1 Custom Subnet
* 1 Firewall Rule
* Jenkins Server
* Docker Server
* SonarQube Server
* Monitoring Server
* Ubuntu 24.04 LTS Operating System
* Deployment Region: asia-south1
* Deployment Zone: asia-south1-c

This infrastructure serves as the foundation for a complete DevSecOps CI/CD platform deployment.
