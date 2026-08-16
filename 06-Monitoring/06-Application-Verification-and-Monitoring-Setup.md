# SecureBank Application Verification & Monitoring Configuration

## Objective

This document covers:

* Kubernetes Cluster Health Verification
* Application Deployment Validation
* LoadBalancer Verification
* Application Accessibility Testing
* Node Exporter Installation using Ansible
* Prometheus Configuration
* Prometheus Target Validation
* Grafana Integration
* Grafana Dashboard Configuration

At the end of this phase, the SecureBank application and infrastructure monitoring stack will be fully operational.

---

# Verify Kubernetes Worker Nodes

Run:

```bash
kubectl get nodes
```

Expected Output:

```text
Ready
Ready
```

Both worker nodes should be in a healthy state.

---

# Verify Namespace

Run:

```bash
kubectl get ns
```

Expected Output:

```text
securebank    Active
```

This confirms that the Kubernetes namespace has been successfully created.

---

# Verify Kubernetes Resources

From the Jenkins VM, run:

```bash
kubectl get all -n securebank
```

Verify:

* Deployments
* ReplicaSets
* Pods
* Services

All resources should be in a Running state.

---

# Verify Service

Run:

```bash
kubectl get svc -n securebank
```

Expected Output:

```text
NAME                 TYPE           EXTERNAL-IP
securebank-service   LoadBalancer   xx.xx.xx.xx
```

The External IP should be assigned successfully.

---

# Test Application Access

Open the application in a browser:

```text
http://EXTERNAL-IP
```

Since the Kubernetes service is configured as:

```yaml
ports:
  - port: 80
    targetPort: 8080
```

The application should be accessible directly through:

```text
http://EXTERNAL-IP
```

Example:

```text
http://34.xx.xx.xx
```

---

# Deployment Health Verification

Run:

```bash
kubectl describe deployment securebank -n securebank
```

Review:

* Replica Status
* Pod Status
* Events
* Deployment Conditions

No errors should be reported.

---

# Service Health Verification

Run:

```bash
kubectl describe svc securebank-service -n securebank
```

Review:

* LoadBalancer Status
* External IP
* Endpoints
* Events

No errors should be present.

---

# Monitoring Stack Verification

From the Monitoring Server, verify the monitoring applications.

---

## Verify Prometheus

Open:

```text
http://<PROMETHEUS_SERVER_IP>:9090
```

Expected:

```text
Prometheus Dashboard Opens Successfully
```

---

## Verify Grafana

Open:

```text
http://<GRAFANA_SERVER_IP>:3000
```

Expected:

```text
Grafana Login Page Opens Successfully
```

---

# Install Node Exporter Using Ansible

Navigate to the Ansible directory on the Jenkins VM.

Create:

```text
sudo nano monitoring-node-exporter-installation.yml
```

---

# monitoring-node-exporter-installation.yml

```yaml
---
- name: Install Node Exporter
  hosts: all
  become: yes

  tasks:

    - name: Create node_exporter user
      user:
        name: node_exporter
        shell: /bin/false
        system: yes

    - name: Download Node Exporter
      get_url:
        url: https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
        dest: /tmp/node_exporter.tar.gz

    - name: Extract Node Exporter
      unarchive:
        src: /tmp/node_exporter.tar.gz
        dest: /tmp
        remote_src: yes

    - name: Copy Binary
      copy:
        src: /tmp/node_exporter-1.8.2.linux-amd64/node_exporter
        dest: /usr/local/bin/node_exporter
        remote_src: yes
        mode: '0755'

    - name: Create Service File
      copy:
        dest: /etc/systemd/system/node_exporter.service
        content: |
          [Unit]
          Description=Node Exporter
          Wants=network-online.target
          After=network-online.target

          [Service]
          User=node_exporter
          Group=node_exporter
          Type=simple
          ExecStart=/usr/local/bin/node_exporter

          [Install]
          WantedBy=multi-user.target

    - name: Reload systemd
      systemd:
        daemon_reload: yes

    - name: Enable Node Exporter
      systemd:
        name: node_exporter
        enabled: yes
        state: started
```

---

Run:

```bash
ansible-playbook -i hosts monitoring-node-exporter-installation.yml
```

# Verify Node Exporter Installation

Run:

```bash
ansible all -i hosts -m shell -a "systemctl status node_exporter --no-pager"
```

Or:

```bash
ansible all -i hosts -m shell -a "ss -tulpn | grep 9100"
```

Expected Output:

```text
LISTEN 0 4096 0.0.0.0:9100
```

This confirms Node Exporter is listening on port 9100.

---

# Verify Node Exporter Metrics

Open the following URLs in a browser:

```text
http://JENKINS_VM_IP:9100/metrics
```

```text
http://SONAR_VM_IP:9100/metrics
```

```text
http://MONITORING_VM_IP:9100/metrics
```

```text
http://MASTER_VM_IP:9100/metrics
```

Expected:

```text
Node Exporter Metrics Page
```

Metrics should be visible.

---

# Configure Prometheus

SSH into the Monitoring VM.

Create:

```bash
sudo nano prometheus.yml
```

Paste:

```yaml
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: "prometheus"

    static_configs:
      - targets:
          - localhost:9090

  - job_name: "jenkins"

    static_configs:
      - targets:
          - JENKINS-IP:9100

  - job_name: "sonarqube"

    static_configs:
      - targets:
          - SONAR-IP:9100

  - job_name: "monitoring"

    static_configs:
      - targets:
          - MONITORING-IP:9100
```

Save:

```text
Ctrl + O
Enter
Ctrl + X
```

---

# Copy Configuration to Prometheus Container

Run:

```bash
docker cp prometheus.yml prometheus:/etc/prometheus/prometheus.yml
```

---

# Restart Prometheus

Run:

```bash
docker restart prometheus
```

Verify:

```bash
docker ps
```

Expected:

```text
Prometheus Container Status: Up
```

---

# Verify Prometheus Targets

Open:

```text
http://Monitoring-IP:9090/targets
```

Expected:

```text
prometheus        UP
jenkins-server    UP
docker-server     UP
sonarqube-server  UP
monitoring-server UP
```

All targets should show:

```text
UP
```

---

# Configure Grafana

Open:

```text
http://136.119.108.107:3000
```

Login to Grafana.

---

# Add Prometheus Data Source

Navigate to:

```text
Connections
→ Add New Connection
```

Search:

```text
Prometheus
```

Select:

```text
Prometheus
```

Click:

```text
Add New Data Source
```

---

# Configure Prometheus Data Source

URL:

```text
http://prometheus:9090
```

If Grafana and Prometheus are running in Docker containers on the same Monitoring VM.

Alternative URLs:

```text
http://136.119.108.107:9090
```

or

```text
http://localhost:9090
```

depending on Docker networking.

---

# Test Data Source Connection

Click:

```text
Save & Test
```

Expected:

```text
Successfully queried the Prometheus API
```

---

# Import Grafana Dashboards

Navigate to:

```text
Dashboards
→ New
→ Import Dashboard
```

Import:

---

## Dashboard 1: Node Exporter Full

Dashboard ID:

```text
1860
```

---

## Dashboard 2: Node Exporter Host Overview

Dashboard ID:

```text
14513
```

Select:

```text
Prometheus Data Source
```

Click:

```text
Import
```

---

# Phase Completion Checklist

* [x] Kubernetes Nodes Verified
* [x] Namespace Verified
* [x] Deployments Verified
* [x] Services Verified
* [x] Application Accessible
* [x] Node Exporter Installed
* [x] Node Exporter Metrics Verified
* [x] Prometheus Configured
* [x] Prometheus Targets Verified
* [x] Grafana Installed
* [x] Prometheus Data Source Added
* [x] Node Exporter Dashboard Imported
* [x] Infrastructure Monitoring Enabled

---

# Monitoring Deployment Status

✅ SecureBank Application Running Successfully

✅ Kubernetes Cluster Healthy

✅ Node Exporter Installed on All Servers

✅ Prometheus Monitoring Active

✅ Grafana Integrated with Prometheus

✅ Infrastructure Metrics Collection Enabled

✅ Monitoring Stack Successfully Configured
