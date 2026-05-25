# Azure Enterprise Infrastructure as Code

This repository contains a complete, production-ready Terraform configuration for deploying a scalable, secure enterprise infrastructure on Microsoft Azure, including Kubernetes (AKS), networking, databases, and DevOps pipelines.

## 📋 What's Included

### Infrastructure
- **Azure Kubernetes Service (AKS)** - Fully configured managed Kubernetes cluster
- **Virtual Networking** - VNets, subnets, and network security groups (NSGs)
- **Database Services** - PostgreSQL, MySQL, and Azure SQL options
- **Storage & CDN** - Blob storage, file shares, and Azure CDN
- **Load Balancing** - Application Gateway, Azure Load Balancer
- **DNS & SSL** - Azure DNS, automated certificate management

### Kubernetes & Application Deployment
- **Helm Charts** - Production-grade application packaging
  - Sample application with auto-scaling and high availability
  - Monitoring stack (Prometheus + Grafana)
  - ArgoCD for GitOps deployments
  - Sealed Secrets for encrypted secret management

### DevOps & Automation
- **GitHub Actions CI/CD** - Four automated workflows
  - Terraform validation and planning
  - Docker container building and pushing to Azure Container Registry
  - Comprehensive security scanning (CodeQL, Checkov, Trivy, TruffleHog)
  - Infrastructure deployment with approval gates and notifications

### Observability & Security
- **Monitoring** - Prometheus metrics collection with Grafana dashboards
- **Alerts** - Pre-configured alert rules for pods, nodes, and resources
- **Security** - Azure Key Vault, managed identities, RBAC, sealed secrets
- **Secret Management** - GitOps-compatible encrypted secrets in version control

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.5.0
- Azure CLI v2.40.0+
- kubectl >= 1.24.0
- PowerShell 7.0+ or Bash

### Setup Steps

```bash
# 1. Initialize Terraform
terraform init

# 2. Configure your environment
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Plan the deployment
terraform plan -out=tfplan

# 4. Apply the configuration
terraform apply tfplan

# 5. Configure kubectl
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw kubernetes_cluster_name)

# 6. Verify the cluster
kubectl get nodes
```

## 🚀 Complete Deployment

For a complete, automated deployment of all components, use the provided script:

```bash
./scripts/deploy-all.sh prod    # or 'dev' for development
```

This 11-step script will:
1. Check all prerequisites
2. Validate Azure authentication
3. Setup Terraform backend
4. Deploy Azure infrastructure
5. Configure kubectl access
6. Add Helm repositories
7. Deploy Sealed Secrets
8. Deploy ArgoCD
9. Deploy Monitoring stack
10. Deploy sample application
11. Verify all deployments

**⏱️ Estimated time: 45-60 minutes**

See `docs/INTEGRATION_GUIDE.md` for detailed step-by-step instructions and troubleshooting.

---

## 📁 Directory Structure

```
.
├── environments/          # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── modules/              # Reusable Terraform modules
│   ├── aks/             # Kubernetes cluster
│   ├── networking/      # VNets, subnets, NSGs
│   ├── database/        # Database services
│   ├── storage/         # Storage accounts
│   ├── monitoring/      # Observability
│   ├── security/        # Key Vault, RBAC
│   └── loadbalancer/    # Application Gateway
├── helm/                # Kubernetes application packages
│   ├── sample-app/      # Example application chart
│   ├── argocd/          # GitOps deployment controller
│   ├── monitoring/      # Prometheus + Grafana stack
│   └── sealed-secrets/  # Encrypted secret management
├── .github/workflows/   # GitHub Actions CI/CD pipelines
│   ├── terraform-validate.yml
│   ├── terraform-deploy.yml
│   ├── container-build.yml
│   └── security-scan.yml
├── scripts/             # Automation scripts
│   └── deploy-all.sh    # Complete deployment automation
├── docs/                # Documentation
│   └── INTEGRATION_GUIDE.md
├── main.tf              # Root module configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable assignments (environment-specific)
└── terraform.lock.hcl   # Dependency lock file
```

## 🏗️ Architecture & Components

### Helm Charts - Application Packaging
**What it is:** Helm is a package manager for Kubernetes that bundles application configurations, making them reusable and versionable.

**What we provide:**
- **sample-app** - Production-ready application deployment with auto-scaling (3-10 replicas), health checks, and pod disruption budgets
- **monitoring** - Complete monitoring stack with Prometheus (metrics collection), Grafana (visualization), and AlertManager
- **argocd** - GitOps deployment controller that automatically deploys apps from Git
- **sealed-secrets** - Encrypts sensitive credentials before committing to Git

**Why it matters:** Teams can package their apps once as Helm charts and deploy consistently across dev, staging, and production environments.

### ArgoCD - GitOps Deployment
**What it is:** A declarative continuous deployment tool that syncs your Git repository with your Kubernetes cluster.

**How it works:**
1. Developer updates app configuration in Git
2. ArgoCD detects the change automatically
3. ArgoCD compares Git state with cluster state
4. Changes are automatically applied to the cluster
5. Self-healing: if someone manually changes the cluster, ArgoCD reverts it back to Git state

**Why it matters:** Your Git repository becomes the single source of truth. All deployments are auditable, versionable, and can be rolled back easily.

### Sealed Secrets - Encrypted Credentials
**What it is:** Encrypts sensitive data (API keys, passwords) before storing in Git.

**How it works:**
1. Create a secret with your credentials
2. Seal it with kubeseal (encryption)
3. Commit encrypted secret to Git (safe!)
4. ArgoCD applies it to the cluster
5. Sealed Secrets controller on the cluster decrypts it
6. Application accesses the decrypted secret

**Why it matters:** You can store all configurations in Git without exposing credentials. No separate secret management system needed.

### Monitoring - Prometheus & Grafana
**What it is:** Real-time monitoring and visualization of your Kubernetes cluster and applications.

**What you get:**
- Pre-built dashboards for cluster health, pod metrics, node status
- Alert rules for common issues (pod crashes, high CPU/memory, node pressure)
- Automatic alerts via Slack/PagerDuty
- 15-day metrics retention

**Why it matters:** Stay informed about cluster health and application performance. Catch issues before they impact users.

### GitHub Actions CI/CD
**What it is:** Automated workflows that validate, build, test, and deploy your infrastructure and applications.

**Included workflows:**
- **terraform-validate** - Validates Terraform syntax, runs TFLint, shows plan on PRs
- **container-build** - Builds Docker images, scans for vulnerabilities, pushes to Azure Container Registry
- **security-scan** - CodeQL, Checkov, Trivy, TruffleHog, and dependency checks
- **terraform-deploy** - Applies Terraform changes after manual approval, notifies Slack

**Why it matters:** Catch errors early, maintain security standards, automate deployment process, audit all changes.

---

## 🔧 Configuration

### Environment Variables

```bash
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
```

### Or use Azure CLI authentication

```bash
az login
az account set --subscription <subscription-id>
```

## 📊 State Management

Terraform state is stored remotely in an Azure Storage Account for team collaboration.

## 📚 Documentation

- **[Integration Guide](docs/INTEGRATION_GUIDE.md)** - Complete guide on how all components work together, integration points, and deployment scenarios
- **[Quick Reference](QUICK_REFERENCE.md)** - Common commands and troubleshooting tips

---

## 🚀 Common Workflows

### Deploy a New Application
```bash
# 1. Create Helm chart for your app
mkdir -p helm/myapp/templates
# ... add Chart.yaml, values.yaml, and templates ...

# 2. Create ArgoCD Application
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/repo
    targetRevision: main
    path: helm/myapp
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# 3. Push to Git - ArgoCD syncs automatically!
git push origin main
```

### Update Infrastructure
```bash
# 1. Modify Terraform files
# 2. Create pull request
# 3. GitHub Actions validates and shows plan
# 4. Review and merge
# 5. GitHub Actions applies changes automatically
```

### Add Encrypted Secrets to Git
```bash
# 1. Create secret
kubectl create secret generic db-creds \
  --from-literal=password=supersecret

# 2. Seal it
kubectl get secret db-creds -o yaml | kubeseal > sealed-secret.yaml

# 3. Commit to Git (encrypted, safe!)
git add sealed-secret.yaml
git commit -m "Add sealed database credentials"
git push origin main

# 4. ArgoCD automatically applies it
# 5. Sealed Secrets controller decrypts it on the cluster
```

### Monitor Your Infrastructure
- **Grafana Dashboard**: `https://grafana.example.com` (after deployment)
- **Pre-built Dashboards**: Kubernetes cluster health, pod metrics, node status
- **Alerts**: Automatic Slack/PagerDuty notifications for critical issues

## 📖 Best Practices Implemented

### Infrastructure as Code
- **Modular Design** - Reusable Terraform modules across environments
- **DRY Principle** - No configuration duplication
- **Version Control** - All code and state tracked in Git
- **Consistent Naming** - Descriptive, organized resource names
- **Tagging Strategy** - All resources tagged for organization and cost tracking

### Security
- **Key Vault Integration** - Secure credential storage
- **RBAC** - Role-based access control on Azure and Kubernetes
- **Encryption** - Data encryption at rest and in transit
- **Sealed Secrets** - Encrypted credentials in Git
- **Network Policies** - Pod-to-pod network restrictions
- **Security Scanning** - CodeQL, Checkov, Trivy automated scans

### Kubernetes Reliability
- **High Availability** - Multi-zone deployments with replicas
- **Auto-scaling** - Horizontal pod autoscaler based on CPU/memory
- **Pod Disruption Budgets** - Ensures minimum replicas during updates
- **Health Checks** - Liveness and readiness probes
- **Rolling Updates** - Zero-downtime deployments

### DevOps & Automation
- **GitOps** - Git as single source of truth via ArgoCD
- **CI/CD Pipeline** - Automated validation, building, and deployment
- **Cost Optimization** - Auto-scaling and right-sizing
- **Observability** - Monitoring, logging, and alerting built-in

---

**Last Updated:** May 2026
