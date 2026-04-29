# SoftBD Laravel Kubernetes Deployment

A production-ready Laravel application deployed on a Kubernetes cluster using Docker, kubeadm, and Helm on AWS EC2.

**Live Cluster:** `https://52.220.106.126:6443`  
**Docker Image:** `hmsmiraz/softbd-task:v1.0.0`  
**GitHub Repository:** [https://github.com/hmsmiraz/softbd_task](https://github.com/hmsmiraz/softbd_task)

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Cluster Setup](#cluster-setup)
- [Docker Build & Push](#docker-build--push)
- [Helm Deployment](#helm-deployment)
- [Testing](#testing)
- [Bonus Features](#bonus-features)
- [Troubleshooting](#troubleshooting)
- [Assumptions](#assumptions)
- [Production Improvement Suggestions](#production-improvement-suggestions)

---

## Architecture Overview

Internet  
│  
▼  
AWS EC2 (ap-southeast-1)  
│  
├── Control Plane 1 (t3.small) - 52.220.106.126  
├── Control Plane 2 (t3.small) - 13.212.249.154  
└── Worker Node    (t3.small) - 47.128.152.86  
│  
├── ingress-nginx (NodePort 30080)  
├── Calico CNI  
└── laravel namespace  
    ├── Laravel App (2 replicas)  
    ├── Queue Worker  
    ├── Scheduler CronJob  
    └── Redis  

---

## Prerequisites

Install these tools before starting:

| Tool | Version | Install |
|------|---------|---------|
| kubectl | v1.30.0 | [Download](https://dl.k8s.io/release/v1.30.0/bin/windows/amd64/kubectl.exe) |
| Helm | v3.14.0 | [Download](https://get.helm.sh/helm-v3.14.0-windows-amd64.zip) |
| Terraform | v1.x | [Install](https://developer.hashicorp.com/terraform/install) |
| AWS CLI | v2 | [Install](https://aws.amazon.com/cli/) |
| Docker Desktop | Latest | [Download](https://www.docker.com/products/docker-desktop/) |
| Git | Latest | [Download](https://git-scm.com/download/win) |

---

## Project Structure
```text

softbd_task/
├── app/                        # Laravel application code
├── routes/
│   └── web.php                 # Application routes
├── docker/
│   ├── nginx/
│   │   └── default.conf        # Nginx configuration
│   └── start.sh                # Container startup script
├── helm/
│   └── laravel-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── namespace.yaml
│           ├── deployment.yaml  # With init container, liveness/readiness probes
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── configmap.yaml
│           ├── secret.yaml
│           ├── pvc.yaml
│           ├── hpa.yaml         # Horizontal Pod Autoscaler
│           ├── pdb.yaml         # Pod Disruption Budget
│           ├── networkpolicy.yaml
│           ├── queue-worker.yaml
│           ├── scheduler.yaml
│           └── redis.yaml
├── terraform/
│   ├── main.tf                  # AWS VPC, EC2, Security Groups
│   ├── variables.tf
│   └── outputs.tf
├── argocd/
│   ├── application.yaml         # ArgoCD Application manifest
│   └── project.yaml             # ArgoCD Project manifest
├── .github/
│   └── workflows/
│       └── ci-cd.yml            # GitHub Actions CI/CD pipeline
├── Dockerfile                   # Multi-stage production Dockerfile
├── .dockerignore
└── README.md
```

## Cluster Setup

### Step 1 — Configure AWS CLI

```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region: ap-southeast-1, Output: json
````

### Step 2 — Generate SSH Key

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-key
```

### Step 3 — Provision Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:

* 1 VPC with public subnet
* 2 Control Plane nodes (t3.small)
* 1 Worker node (t3.small)
* Security groups with all required Kubernetes ports
* Elastic IP for Control Plane 1

### Step 4 — Install Kubernetes on All Nodes

```bash
scp -i ~/.ssh/k8s-key terraform/k8s-install.sh ubuntu@<NODE_IP>:~/k8s-install.sh
ssh -i ~/.ssh/k8s-key ubuntu@<NODE_IP> "chmod +x ~/k8s-install.sh && sudo ~/k8s-install.sh"
```

Repeat for all 3 nodes: Control Plane 1, Control Plane 2, Worker.

---

## Docker Build & Push

### Build

```bash
docker build -t hmsmiraz/softbd-task:latest .
docker build -t hmsmiraz/softbd-task:v1.0.0 .
```

### Push

```bash
docker login
docker push hmsmiraz/softbd-task:latest
docker push hmsmiraz/softbd-task:v1.0.0
```

---

## Helm Deployment

### Install

```bash
helm install laravel-app helm/laravel-app \
  --namespace laravel \
  --create-namespace \
  --set secret.appKey="base64:YOUR_APP_KEY" \
  --set image.repository=hmsmiraz/softbd-task \
  --set image.tag=v1.0.0 \
  --set redis.enabled=true
```

---

## Testing

### Add to /etc/hosts (Linux/Mac)

```bash
echo "52.220.106.126   laravel-test.local" | sudo tee -a /etc/hosts
```

### Add to hosts file (Windows)

Open Command Prompt as Administrator:

```cmd
echo 52.220.106.126   laravel-test.local >> C:\Windows\System32\drivers\etc\hosts
```

### Test Endpoints

```bash
curl http://laravel-test.local:30080
# Expected: Laravel Kubernetes Deployment Test

curl http://laravel-test.local:30080/health
# Expected: {"status":"ok","timestamp":"..."}
```

### Test via Direct IP

```bash
curl -H "Host: laravel-test.local" http://52.220.106.126:30080
curl -H "Host: laravel-test.local" http://52.220.106.126:30080/health
```

### Required Laravel Commands

```bash
# These run automatically in docker/start.sh on container startup:
php artisan config:cache   # Caches configuration for performance
php artisan route:cache    # Caches routes for performance
php artisan storage:link   # Creates public storage symlink

# Run manually if needed:
php artisan migrate        # Not run automatically - no database configured by default
```

---

## Bonus Features

| Feature                 | Status | Details                                            |
| ----------------------- | ------ | -------------------------------------------------- |
| HPA                     | ✅      | Scales 2-5 replicas at 70% CPU                     |
| PodDisruptionBudget     | ✅      | Minimum 1 pod always available                     |
| NetworkPolicy           | ✅      | Only ingress-nginx can reach Laravel pods          |
| Queue Worker            | ✅      | Separate deployment running php artisan queue:work |
| Scheduler CronJob       | ✅      | Runs php artisan schedule:run every minute         |
| ArgoCD                  | ✅      | Manifest in argocd/ folder                         |
| CI/CD Pipeline          | ✅      | GitHub Actions - test, build, push, deploy         |
| Private Registry Secret | ✅      | dockerhub-secret in laravel namespace              |
| Non-root Container      | ✅      | Runs as user 1000 (www)                            |
| Multi-stage Dockerfile  | ✅      | Composer build stage + production stage            |
| Redis                   | ✅      | Redis pod deployed, configured in Helm             |
| External Database       | 📝     | See note below                                     |
| TLS/cert-manager        | 📝     | See note below                                     |

### ArgoCD Setup

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application.yaml
```

### CI/CD Pipeline

The GitHub Actions pipeline at `.github/workflows/ci-cd.yml` runs:

1. **Test** — PHP unit tests on every push and PR
2. **Build & Push** — Docker image pushed to Docker Hub on main branch
3. **Deploy** — Helm upgrade to Kubernetes cluster

> **Note on CI/CD Deploy Step:** The deploy step requires the GitHub Actions runner to reach the cluster API at `52.220.106.126:6443`. In production this would use a self-hosted runner inside the VPC or a VPN connection. The pipeline structure is correct and the test + build stages work successfully.

---

## Assumptions

1. **SQLite for local development** — The app uses SQLite locally. In production, an external MySQL/PostgreSQL database (e.g., AWS RDS) should be used.

2. **File-based sessions** — Sessions use the file driver since no external database is configured. With Redis fully enabled (PHP Redis extension installed), sessions would use Redis.

3. **PHP Redis extension** — The Redis pod is deployed and running. The PHP Redis extension (pecl) was not compiled into the Docker image due to slow internet connectivity during build. The Dockerfile includes the correct build instructions. In production, a CI/CD environment with fast internet would compile this successfully.

4. **Single availability zone** — All nodes are in `ap-southeast-1a`. Production should span multiple AZs.

5. **NodePort for ingress** — Used NodePort (30080) instead of LoadBalancer since there is no cloud load balancer configured. In production, use AWS ALB with the AWS Load Balancer Controller.

6. **Self-signed/no TLS** — TLS was not configured due to time constraints. cert-manager with Let's Encrypt would be the production approach.

7. **kubeadm on EC2** — Used kubeadm directly on EC2 instances as required. AWS EKS was deliberately not used to comply with the assignment requirements.

---

## Production Improvement Suggestions

1. **External Database (RDS)** — Replace SQLite/file storage with AWS RDS MySQL or PostgreSQL. Configure via Helm values:

```yaml
   env:
     DB_CONNECTION: mysql
     DB_HOST: your-rds-endpoint.rds.amazonaws.com
     DB_DATABASE: laravel
```

2. **TLS with cert-manager** — Install cert-manager and use Let's Encrypt:

```bash
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
```

3. **AWS Secrets Manager** — Use External Secrets Operator to inject APP_KEY and DB credentials from AWS Secrets Manager instead of Kubernetes Secrets.

4. **Multi-AZ deployment** — Spread nodes across multiple availability zones for high availability.

5. **AWS ALB** — Use AWS Load Balancer Controller with ALB instead of NodePort for production traffic.

6. **Monitoring** — Add Prometheus + Grafana for metrics and alerting.

7. **Log aggregation** — Add Fluentd/CloudWatch for centralized logging.

8. **PHP Redis extension** — Add `pecl install redis` to Dockerfile for full Redis cache and session support.

9. **Database migrations** — Run `php artisan migrate` as a Kubernetes Job before deployment rolls out.

10. **Resource scaling** — Upgrade to larger instance types (t3.medium or higher) for production workloads.

---

## Troubleshooting

| Problem                    | Solution                                                                                                                        |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Pods stuck in Pending      | Check PVC: `kubectl get pvc -n laravel`                                                                                         |
| ImagePullBackOff           | Check dockerhub-secret: `kubectl get secret dockerhub-secret -n laravel`                                                        |
| CrashLoopBackOff           | Check logs: `kubectl logs <pod-name> -n laravel`                                                                                |
| Ingress not routing        | Verify ingress-nginx is running: `kubectl get pods -n ingress-nginx`                                                            |
| 404 from nginx             | Ensure Host header matches: `curl -H "Host: laravel-test.local" http://52.220.106.126:30080`                                    |
| Storage not working        | Run: `kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml` |
| Nodes NotReady             | Check Calico pods: `kubectl get pods -n kube-system \| grep calico`                                                             |
| kubeadm join token expired | On CP1: `kubeadm token create --print-join-command`                                                                             |
| Permission denied SSH      | Fix key permissions: `icacls ~/.ssh/k8s-key /inheritance:r`                                                                     |

---

**To stop:**

```bash
cd terraform
terraform destroy
```

---

## Important Notes

* No sensitive values are hardcoded in any Deployment or ConfigMap
* APP_KEY is stored in a Kubernetes Secret
* Docker Hub credentials are stored in an imagePullSecret

