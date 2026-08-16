# 04-GKE-Terraform-Deployment.md

# Google Kubernetes Engine (GKE) Deployment using Terraform

## Project Details

| Parameter | Value |
|------------|---------|
| Project ID | bankingproject2027 |
| VPC | bankingproject2027-vpc |
| Existing Subnet | bankingproject2027-subnet |
| Application | Banking-3Tier-Warfile |
| Cluster Name | securebank-gke |
| Node Pool | securebank-nodepool |
| Namespace | securebank |
| Region | asia-south1 |
| Zone | asia-south1-c |

---

# Folder Structure

```text
04-GKE/
│
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── main.tf
├── outputs.tf
│
└── k8s/
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

---

# provider.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  credentials = file("terraform-key.json")

  project = var.project_id
  region  = var.region
  zone    = var.zone
}
```

---

# variables.tf

```hcl
variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}

variable "network_name" {
  type = string
}

variable "gke_subnet_name" {
  type = string
}

variable "gke_subnet_cidr" {
  type = string
}

variable "pods_secondary_range" {
  type = string
}

variable "services_secondary_range" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "node_count" {
  type = number
}

variable "machine_type" {
  type = string
}
```

---

# terraform.tfvars

```hcl
project_id = "bankingproject2027"

region = "asia-south1"

zone = "asia-south1-c"

network_name = "bankingproject2027-vpc"

gke_subnet_name = "securebank-gke-subnet"

gke_subnet_cidr = "10.20.0.0/24"

pods_secondary_range = "10.30.0.0/16"

services_secondary_range = "10.40.0.0/20"

cluster_name = "securebank-gke"

node_count = 2

machine_type = "e2-standard-2"
```

---

# main.tf

```hcl
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
      managed_by  = "terraform"
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
```

---

# outputs.tf

```hcl
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
```

---

# Enable Required APIs

```bash
gcloud config set project bankingproject2027

gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

---

# Terraform Deployment

```bash
terraform fmt
terraform init
terraform validate
terraform plan
```

Expected Output:

```text
Plan: 3 to add, 0 to change, 0 to destroy
```

Resources:

```text
securebank-gke
securebank-nodepool
securebank-gke-subnet
```

Deploy:

```bash
terraform apply
```

---

# Verify GKE Cluster

```bash
gcloud container clusters list
```

Expected:

```text
NAME            : securebank-gke
LOCATION        : asia-south1-c
STATUS          : RUNNING
NODES           : 2
```

---

# Configure kubectl Authentication

```bash
gcloud container clusters get-credentials securebank-gke \ --zone asia-south1-c
```

Verify:

```bash
kubectl get nodes
```

Expected:

```text
Ready
Ready
```

---

# Create Kubernetes Namespace

## k8s/namespace.yaml

```yaml
apiVersion: v1
kind: Namespace

metadata:
  name: securebank
```

Apply:

```bash
kubectl apply -f k8s/namespace.yaml
```

Verify:

```bash
kubectl get ns
```

Expected:

```text
securebank
```

---

# Create Deployment

## k8s/deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: securebank
  namespace: securebank

spec:
  replicas: 2

  selector:
    matchLabels:
      app: securebank

  template:
    metadata:
      labels:
        app: securebank

    spec:
      containers:
      - name: securebank

        image: devopsbyrushi/securebank:latest

        imagePullPolicy: Always

        ports:
        - containerPort: 8080

        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"

          limits:
            cpu: "500m"
            memory: "512Mi"
```

---

# Create Service

## k8s/service.yaml

```yaml
apiVersion: v1
kind: Service

metadata:
  name: securebank-service
  namespace: securebank

spec:
  selector:
    app: securebank

  type: LoadBalancer

  ports:
  - port: 80
    targetPort: 8080
```

---

# Deploy Application

```bash
kubectl apply -f k8s/deployment.yaml

kubectl apply -f k8s/service.yaml
```

Verify:

```bash
kubectl get all -n securebank
```

Expected:

```text
deployment.apps/securebank
replicaset.apps/securebank
pod/securebank-xxxxx
pod/securebank-yyyyy
```

Status:

```text
2/2 Running
```

---

# Verify Service

```bash
kubectl get svc -n securebank
```

Wait until an External IP is assigned.

Example:

```text
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP
securebank-service   LoadBalancer   10.40.12.139   34.xxx.xxx.xxx
```

Access Application:

```text
http://34.xxx.xxx.xxx
```

---

# Jenkins VM Prerequisites

Verify installed tools:

```bash
mvn -version

java -version

docker --version

kubectl version --client
```

---

# Install kubectl on Jenkins VM

```bash
sudo apt-get update

sudo apt-get install -y kubectl
```

Alternative:

```bash
sudo snap install kubectl --classic
```

Verify:

```bash
kubectl version --client
```

---

# Verify GCloud

```bash
gcloud version
```

---

# Connect Jenkins VM to GKE

```bash
gcloud container clusters get-credentials securebank-gke \
--zone asia-south1-c
```

Verify:

```bash
kubectl get nodes
```

Expected:

```text
gke-securebank-nodepool-xxxxx Ready
gke-securebank-nodepool-yyyyy Ready
```

---

# Install GKE Authentication Plugin

```bash
sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates gnupg curl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt-get update

sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
```

Verify:

```bash
gke-gcloud-auth-plugin --version
```

Enable Plugin:

```bash
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
which gke-gcloud-auth-plugin
```

---
# Authenticate Jenkins VM

```bash
gcloud auth login

gcloud config set project bankingproject2027
```

Verify:

```bash
gcloud auth list
```

Expected:

```text
ACTIVE ACCOUNT
* your-email@gmail.com
```

---

# Final Cluster Verification

```bash
gcloud container clusters get-credentials securebank-gke \
--zone asia-south1-c \
--project bankingproject2027

kubectl get nodes
```

Expected:

```text
NAME                                STATUS
gke-securebank-nodepool-xxxxx       Ready
gke-securebank-nodepool-yyyyy       Ready
```

---

# Deployment Status

- [x] Terraform Configuration Created
- [x] GKE Cluster Provisioned
- [x] Node Pool Created
- [x] Namespace Created
- [x] Deployment Created
- [x] Service Created
- [x] External Load Balancer Configured
- [x] Jenkins Connected to GKE
- [x] GKE Authentication Configured
- [x] SecureBank Application Successfully Running on GKE
