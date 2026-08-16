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