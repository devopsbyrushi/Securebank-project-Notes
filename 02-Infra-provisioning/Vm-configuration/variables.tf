variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-a"
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