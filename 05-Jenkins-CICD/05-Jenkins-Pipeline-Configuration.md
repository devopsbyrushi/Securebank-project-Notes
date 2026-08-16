# 05-Jenkins Pipeline Configuration for SecureBank GKE Project

## Objective

This document covers the complete Jenkins Pipeline configuration required for:

* GitHub Integration
* SonarQube Code Analysis
* DockerHub Image Push
* GKE Deployment Validation

At the end of this phase, Jenkins will be capable of:

* Pulling source code from GitHub
* Performing SonarQube Analysis
* Building the Maven Application
* Building Docker Images
* Pushing Images to DockerHub
* Deploying the Application to GKE

---

# Jenkins Pipeline Configuration

Navigate to:

```text
Jenkins Dashboard
→ New Item
→ Pipeline
```

Configure the Pipeline section as follows:

## Repository URL

```text
https://github.com/<your-username>/<repo-name>.git
```

Example:

```text
https://github.com/rushiawslabs/securebank.git
```

---

## Credentials

```text
-none-
```

Leave credentials as **None** if the repository is public.

---

## Branch Specifier

```text
*/main
```

If your repository uses the master branch:

```text
*/master
```

---

## Script Path

```text
Jenkinsfile
```

Save the configuration.

---

# Install SonarQube Scanner Plugin

Navigate to:

```text
Manage Jenkins
→ Plugins
→ Available Plugins
```

Search for:

```text
SonarQube Scanner
```

Install:

```text
SonarQube Scanner Plugin
```

After installation:

```text
Restart Jenkins
```

if prompted.

---

# Generate SonarQube Token

Login to SonarQube:

```text
http://<SONARQUBE-IP>:9000
```

Navigate to:

```text
Profile Icon
→ My Account
→ Security
```

Under Tokens:

Create:

```text
Token Name: jenkins-token
```

Click:

```text
Generate
```

Example Token:

```text
sqp_xxxxxxxxxxxxxxxxxxxxx
```

> Important: Copy the token immediately and store it securely.

---

# Add SonarQube Token in Jenkins Credentials

Navigate to:

```text
Manage Jenkins
→ Credentials
→ System
→ Global Credentials
→ Add Credentials
```

Fill the details:

| Field       | Value                 |
| ----------- | --------------------- |
| Kind        | Secret Text           |
| Secret      | Paste SonarQube Token |
| ID          | sonarqube-token       |
| Description | SonarQube Token       |

Click:

```text
Create
```

---

# Configure SonarQube Server in Jenkins

Navigate to:

```text
Manage Jenkins
→ System
```

Locate:

```text
SonarQube Servers
```

Click:

```text
Add SonarQube
```

Fill:

| Parameter            | Value                      |
| -------------------- | -------------------------- |
| Name                 | sonarqube                  |
| Server URL           | http://<SONARQUBE-IP>:9000 |
| Authentication Token | sonarqube-token            |

Example:

```text
http://34.xx.xx.xx:9000
```

Select:

```text
sonarqube-token
```

Enable:

```text
Environment Variables
```

Click:

```text
Save
```

---

# DockerHub Configuration

## Step 1: Login to DockerHub

Open:

```text
https://hub.docker.com
```

Login using your DockerHub account.

---

## Step 2: Open Account Settings

Navigate to:

```text
Profile Icon
→ Account Settings
```

---

## Step 3: Open Personal Access Tokens

Navigate to:

```text
Account Settings
→ Personal Access Tokens
```

Direct URL:

```text
https://hub.docker.com/settings/personal-access-tokens
```

---

## Step 4: Generate New Token

Click:

```text
Generate New Token
```

Fill:

| Parameter   | Value               |
| ----------- | ------------------- |
| Description | jenkins-gke-project |
| Permissions | Read, Write, Delete |

Recommended for CI/CD:

```text
Read & Write
```

---

## Step 5: Generate Token

Click:

```text
Generate
```

Example:

```text
dckr_pat_xxxxxxxxxxxxxxxxxxxxxxxxx
```

> Important: Copy the token immediately. DockerHub may not display it again.

---

# Add DockerHub Credentials in Jenkins

Navigate to:

```text
Manage Jenkins
→ Credentials
→ System
→ Global Credentials
→ Add Credentials
```

Configure:

| Field    | Value                              |
| -------- | ---------------------------------- |
| Username | devopsbyrushi                      |
| Password | DockerHub Password or Access Token |
| ID       | dockerhub-creds                    |

Click:

```text
Create
```

---

# Pre-Build Verification

Before triggering the Jenkins pipeline, verify all required tools.

---

## Verify Java

```bash
java -version
```

---

## Verify Maven

```bash
mvn -version
```

---

## Verify Docker

```bash
docker --version
```

---

## Verify Jenkins Docker Access

```bash
sudo -u jenkins docker ps
```

Expected:

```text
Container list should be displayed without permission errors.
```

---

## Verify SonarQube Reachability

From Jenkins VM:

```bash
curl http://SONAR-IP:9000
```

Expected:

```text
SonarQube login page HTML response
```

---

# Run Jenkins Pipeline

Once all validations are successful:

Navigate to:

```text
Jenkins Dashboard
→ SecureBank Pipeline
```

Click:

```text
Build Now
```

---

# Expected Pipeline Result

The Jenkins Pipeline should execute the following stages successfully:

```text
Git Checkout
↓
Maven Build
↓
SonarQube Analysis
↓
Docker Build
↓
DockerHub Push
↓
Kubernetes Deployment
```

Expected Output:

```text
Kubernetes : DEPLOYMENT SUCCESS
```

---

# Verify DockerHub Image Push

Open:

```text
https://hub.docker.com
```

Navigate to your repositories.

Verify that the following repository exists:

```text
devopsbyrushi/securebank
```

A newly pushed image tag should be visible.

Example:

```text
Repository:
devopsbyrushi/securebank

Latest Tag:
latest
```

---

# Validation Checklist

* [x] GitHub Repository Connected
* [x] Jenkins Pipeline Configured
* [x] SonarQube Scanner Plugin Installed
* [x] SonarQube Token Generated
* [x] SonarQube Server Configured
* [x] DockerHub Access Token Generated
* [x] DockerHub Credentials Added
* [x] Java Verified
* [x] Maven Verified
* [x] Docker Verified
* [x] Jenkins Docker Access Verified
* [x] SonarQube Connectivity Verified
* [x] Jenkins Pipeline Executed Successfully
* [x] Docker Image Pushed Successfully
* [x] Kubernetes Deployment Successful

---

# Phase Completion Status

✅ Jenkins Pipeline Configured

✅ SonarQube Integrated

✅ DockerHub Integrated

✅ SecureBank Docker Image Published

✅ Kubernetes Deployment Successful

✅ CI/CD Pipeline Ready for Production Deployment
