# Jenkins VM -- GKE Kubernetes Deployment Setup

## Overview

This document explains the Jenkins VM configuration required to allow a
Jenkins CI/CD pipeline to deploy and verify applications on a Google
Kubernetes Engine (GKE) cluster.

### Working architecture

``` text
Jenkins Pipeline
       |
       | sudo -u ansible -H kubectl
       v
   ansible user
       |
       | /home/ansible/.kube/config
       |
       | gke-gcloud-auth-plugin
       v
   GKE API Server
       |
       v
 SecureBank GKE Cluster
       |
   +---+----------------+
   |                    |
Deployment            Service
securebank        securebank-service
   |
   v
  Pods
```

The important point is that Jenkins normally runs as the `jenkins` Linux
user, while the working GKE kubeconfig is maintained by the `ansible`
user. Therefore, the pipeline executes Kubernetes commands as `ansible`.

------------------------------------------------------------------------

# 1. Prerequisites

The Jenkins VM should have:

-   Google Cloud CLI (`gcloud`)
-   `kubectl`
-   `gke-gcloud-auth-plugin`
-   An `ansible` Linux user
-   A `jenkins` Linux user
-   Network access to the GKE cluster
-   Correct GKE permissions for the Google Cloud identity being used

Check the tools:

``` bash
which gcloud
which kubectl
which gke-gcloud-auth-plugin
```

Expected paths in the working setup were similar to:

``` text
kubectl:
/snap/bin/kubectl

gke-gcloud-auth-plugin:
/usr/bin/gke-gcloud-auth-plugin
```

The exact paths can differ between VMs.

------------------------------------------------------------------------

# 2. Install kubectl

Check whether `kubectl` is already installed:

``` bash
which kubectl
```

If it is not installed and Snap is being used:

``` bash
sudo snap install kubectl --classic
```

Verify:

``` bash
kubectl version --client
```

## Why is kubectl required?

`kubectl` is the Kubernetes command-line tool.

Jenkins uses it to perform operations such as:

``` bash
kubectl apply
kubectl get pods
kubectl get svc
kubectl wait
```

------------------------------------------------------------------------

# 3. Install the GKE authentication plugin

Check:

``` bash
which gke-gcloud-auth-plugin
```

Verify:

``` bash
gke-gcloud-auth-plugin --version
```

The kubeconfig used by the working setup contains an authentication
configuration similar to:

``` yaml
users:
- name: gke_bankingproject2027_asia-south1-c_securebank-gke
  user:
    exec:
      command: gke-gcloud-auth-plugin
```

## Why is the plugin required?

`kubectl` needs authentication when connecting to GKE.

The authentication flow is:

``` text
kubectl
   |
   v
gke-gcloud-auth-plugin
   |
   v
Google Cloud authentication
   |
   v
GKE API Server
```

Without the required authentication mechanism, Kubernetes commands from
Jenkins can fail with authentication errors.

------------------------------------------------------------------------

# 4. Configure the GKE project

Switch to the `ansible` user:

``` bash
sudo su - ansible
```

Check the Google Cloud account:

``` bash
gcloud auth list
```

Set the correct project:

``` bash
gcloud config set project bankingproject2027
```

Verify:

``` bash
gcloud config get-value project
```

Expected:

``` text
bankingproject2027
```

------------------------------------------------------------------------

# 5. Configure GKE credentials for ansible

Use the GKE cluster credentials command.

Example:

``` bash
gcloud container clusters get-credentials securebank-gke \
  --zone asia-south1-c \
  --project bankingproject2027
```

If the cluster is regional rather than zonal, use the appropriate
`--region` option.

## What this does

This command configures `kubectl` to communicate with the GKE cluster.

It creates or updates the kubeconfig file:

``` text
/home/ansible/.kube/config
```

The kubeconfig contains information such as:

-   Kubernetes cluster
-   Kubernetes API server
-   Cluster certificate information
-   Current context
-   Authentication method

------------------------------------------------------------------------

# 6. Verify the kubeconfig

Check the file:

``` bash
ls -l /home/ansible/.kube/config
```

The working environment showed:

``` text
-rw------- 1 ansible ansible /home/ansible/.kube/config
```

This means:

-   Owner: `ansible`
-   Group: `ansible`
-   File permissions: owner read/write only

This is preferable to making the kubeconfig world-readable.

Check the current context:

``` bash
kubectl config current-context
```

Example:

``` text
gke_bankingproject2027_asia-south1-c_securebank-gke
```

You can also inspect the active configuration:

``` bash
kubectl config view --minify
```

------------------------------------------------------------------------

# 7. Test GKE connectivity as ansible

Run:

``` bash
kubectl get nodes
```

Expected result:

``` text
NAME                                      STATUS   ROLES
gke-securebank-gke-securebank-nodepool... Ready    <none>
gke-securebank-gke-securebank-nodepool... Ready    <none>
```

The important value is:

``` text
STATUS = Ready
```

## Why test this?

Before configuring Jenkins, first confirm that the Kubernetes connection
works for the user who owns the kubeconfig.

The working flow should be:

``` text
ansible
  |
  v
kubectl
  |
  v
gke-gcloud-auth-plugin
  |
  v
GKE
```

If this test fails, do not continue to Jenkins configuration until the
GKE connection is fixed.

------------------------------------------------------------------------

# 8. Understand the Jenkins user problem

Jenkins normally executes pipeline shell commands as:

``` text
jenkins
```

But the working Kubernetes configuration is:

``` text
/home/ansible/.kube/config
```

and is owned by:

``` text
ansible
```

Therefore, simply running this from Jenkins:

``` bash
kubectl get nodes
```

may not use the correct kubeconfig.

The required execution flow is:

``` text
jenkins
   |
   v
sudo -u ansible
   |
   v
kubectl
   |
   v
/home/ansible/.kube/config
   |
   v
GKE
```

This allows the existing `ansible` Kubernetes configuration to remain
unchanged.

------------------------------------------------------------------------

# 9. Configure sudo permission

Open the sudoers configuration safely:

``` bash
sudo visudo
```

Add the required rule for Jenkins to run `kubectl` as `ansible`.

For a VM where `kubectl` is located at `/snap/bin/kubectl`:

``` text
jenkins ALL=(ansible) NOPASSWD: /snap/bin/kubectl
```

If `which kubectl` returns a different path, use that exact path.

For example:

``` bash
which kubectl
```

If it returns:

``` text
/usr/local/bin/kubectl
```

then the sudoers rule should use:

``` text
jenkins ALL=(ansible) NOPASSWD: /usr/local/bin/kubectl
```

## Why is this required?

The Jenkins pipeline needs to execute Kubernetes commands without
stopping for an interactive sudo password prompt.

The permission allows:

``` text
jenkins
   |
   | sudo -u ansible
   v
ansible
   |
   v
kubectl
```

The `NOPASSWD` option is important for non-interactive Jenkins jobs.

------------------------------------------------------------------------

# 10. Test kubectl as ansible

From the Jenkins VM:

``` bash
sudo -u ansible -H kubectl get nodes
```

Expected:

``` text
NAME                                      STATUS
gke-securebank-gke-securebank-nodepool... Ready
gke-securebank-gke-securebank-nodepool... Ready
```

The `-H` option makes the command use the `ansible` user's home
directory.

This is important because the kubeconfig is located at:

``` text
/home/ansible/.kube/config
```

------------------------------------------------------------------------

# 11. Test the exact Jenkins access

This is the most important validation command:

``` bash
sudo -u jenkins sudo -u ansible -H kubectl get nodes
```

Expected:

``` text
NAME                                      STATUS
gke-securebank-gke-securebank-nodepool... Ready
gke-securebank-gke-securebank-nodepool... Ready
```

If this works, Jenkins can execute Kubernetes commands using the
`ansible` user's working GKE configuration.

------------------------------------------------------------------------

# 12. Verify the Kubernetes namespace

The application namespace is:

``` text
securebank
```

Check:

``` bash
sudo -u ansible -H kubectl get pods -n securebank
```

Expected:

``` text
NAME                         READY   STATUS
securebank-xxxxxxxxxx       1/1     Running
securebank-xxxxxxxxxx       1/1     Running
```

The important values are:

``` text
READY  = 1/1
STATUS = Running
```

------------------------------------------------------------------------

# 13. Verify the Kubernetes deployment

Run:

``` bash
sudo -u ansible -H kubectl get deployment -n securebank
```

Expected example:

``` text
NAME        READY   UP-TO-DATE   AVAILABLE
securebank  2/2     2            2
```

This confirms that the Deployment is available.

------------------------------------------------------------------------

# 14. Verify the Kubernetes Service

Run:

``` bash
sudo -u ansible -H kubectl get svc -n securebank
```

The working environment showed:

``` text
NAME                TYPE           CLUSTER-IP     EXTERNAL-IP
securebank-service  LoadBalancer   10.40.5.141    34.180.49.164
```

The actual Service name is:

``` text
securebank-service
```

It is NOT:

``` text
securebank
```

Therefore, the correct command to check the specific Service is:

``` bash
sudo -u ansible -H kubectl get svc securebank-service -n securebank
```

------------------------------------------------------------------------

# 15. Important Kubernetes naming

Keep these names separate:

``` text
Namespace:
securebank

Deployment:
securebank

Service:
securebank-service
```

Kubernetes resources do not have to use the same name.

For example:

``` text
securebank
    |
    +---- Deployment: securebank
    |
    +---- Pods: securebank-xxxxxxxxxx
    |
    +---- Service: securebank-service
```

This distinction is important in the Jenkins pipeline.

------------------------------------------------------------------------

# 16. Jenkinsfile environment variables

The Jenkinsfile should use separate variables for the Deployment and
Service.

Example:

``` groovy
environment {
    K8S_NAMESPACE = 'securebank'
    K8S_DEPLOYMENT = 'securebank'
    K8S_SERVICE = 'securebank-service'
}
```

Then the Service verification command should use:

``` groovy
sudo -u ansible -H kubectl get svc \
${K8S_SERVICE} \
-n ${K8S_NAMESPACE}
```

This prevents Jenkins from trying to find a Service named `securebank`
when the actual Service is `securebank-service`.

------------------------------------------------------------------------

# 17. Kubernetes deployment commands in Jenkins

The Jenkins pipeline can use the `ansible` user for Kubernetes
operations.

Example:

``` bash
sudo -u ansible -H kubectl apply \
-f k8s/deployment.yaml \
-n ${K8S_NAMESPACE}
```

For the Service:

``` bash
sudo -u ansible -H kubectl apply \
-f k8s/service.yaml \
-n ${K8S_NAMESPACE}
```

For checking pods:

``` bash
sudo -u ansible -H kubectl get pods \
-n ${K8S_NAMESPACE} \
-l app=securebank \
-o wide
```

For waiting for pods:

``` bash
sudo -u ansible -H kubectl wait \
--for=condition=Ready \
pod \
-l app=securebank \
-n ${K8S_NAMESPACE} \
--timeout=5m
```

For checking the Service:

``` bash
sudo -u ansible -H kubectl get svc \
${K8S_SERVICE} \
-n ${K8S_NAMESPACE}
```

------------------------------------------------------------------------

# 18. Complete Jenkins VM validation

Run these commands in order.

### Check Google Cloud CLI

``` bash
gcloud --version
```

### Check kubectl

``` bash
which kubectl
kubectl version --client
```

### Check GKE authentication plugin

``` bash
which gke-gcloud-auth-plugin
gke-gcloud-auth-plugin --version
```

### Check kubeconfig

``` bash
ls -l /home/ansible/.kube/config
```

### Check Kubernetes context

``` bash
sudo -u ansible -H kubectl config current-context
```

### Check GKE nodes

``` bash
sudo -u ansible -H kubectl get nodes
```

### Check application pods

``` bash
sudo -u ansible -H kubectl get pods -n securebank
```

### Check deployment

``` bash
sudo -u ansible -H kubectl get deployment -n securebank
```

### Check Service

``` bash
sudo -u ansible -H kubectl get svc -n securebank
```

### Test Jenkins access

``` bash
sudo -u jenkins sudo -u ansible -H kubectl get nodes
```

------------------------------------------------------------------------

# 19. Troubleshooting

## Error: `current-context is not set`

Check:

``` bash
sudo -u ansible -H kubectl config current-context
```

If no context exists, configure GKE credentials again:

``` bash
sudo su - ansible
```

Then:

``` bash
gcloud container clusters get-credentials securebank-gke \
  --zone asia-south1-c \
  --project bankingproject2027
```

------------------------------------------------------------------------

## Error: `gke-gcloud-auth-plugin not found`

Check:

``` bash
which gke-gcloud-auth-plugin
```

Also test as `ansible`:

``` bash
sudo -u ansible -H which gke-gcloud-auth-plugin
```

The executable must be available to the environment used by `kubectl`.

------------------------------------------------------------------------

## Error: `You are authenticated as anonymous`

This usually indicates that the Kubernetes command is not using the
expected GKE authentication configuration.

Check:

``` bash
sudo -u ansible -H kubectl config view --minify
```

Look for:

``` yaml
exec:
  command: gke-gcloud-auth-plugin
```

Also check:

``` bash
sudo -u ansible -H kubectl config current-context
```

------------------------------------------------------------------------

## Error: `services "securebank" not found`

Check the actual Service:

``` bash
sudo -u ansible -H kubectl get svc -n securebank
```

If the result is:

``` text
securebank-service
```

then use:

``` bash
sudo -u ansible -H kubectl get svc securebank-service -n securebank
```

Do not use:

``` bash
kubectl get svc securebank -n securebank
```

------------------------------------------------------------------------

## Error: Jenkins asks for a sudo password

Check the sudoers configuration:

``` bash
sudo visudo
```

Make sure the Jenkins-to-ansible permission is configured correctly.

Then test:

``` bash
sudo -u jenkins sudo -u ansible -H kubectl get nodes
```

------------------------------------------------------------------------

# 20. Final working flow

The complete working setup is:

``` text
Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    | Pipeline
    |
    v
Jenkins Linux User
    |
    | sudo -u ansible
    v
Ansible Linux User
    |
    | kubectl
    |
    v
/home/ansible/.kube/config
    |
    | gke-gcloud-auth-plugin
    v
Google Kubernetes Engine
    |
    +--------------------------+
    |                          |
    v                          v
Deployment                  Service
securebank              securebank-service
    |
    v
Pods
```

------------------------------------------------------------------------

# 21. Final checklist

Before considering the Jenkins VM setup complete, verify:

-   [ ] `gcloud` is installed
-   [ ] `kubectl` is installed
-   [ ] `gke-gcloud-auth-plugin` is installed
-   [ ] Correct GCP project is configured
-   [ ] GKE credentials are configured for `ansible`
-   [ ] `/home/ansible/.kube/config` exists
-   [ ] `ansible` can run `kubectl get nodes`
-   [ ] Jenkins can run `kubectl` as `ansible`
-   [ ] `securebank` namespace exists
-   [ ] `securebank` Deployment exists
-   [ ] SecureBank pods are `Running`
-   [ ] `securebank-service` exists
-   [ ] Jenkinsfile uses `K8S_SERVICE = 'securebank-service'`
-   [ ] Jenkins pipeline completes successfully

## Key takeaway

The main Jenkins VM configuration is:

``` text
Install kubectl
      +
Install GKE auth plugin
      +
Configure GKE kubeconfig for ansible
      +
Allow Jenkins to execute kubectl as ansible
      +
Test Jenkins → ansible → kubectl → GKE
```

Once this flow works, Jenkins can deploy and verify the Kubernetes
application without moving the existing kubeconfig away from the
`ansible` user.
