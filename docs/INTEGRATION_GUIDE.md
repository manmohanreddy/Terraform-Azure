# Integration Guide - Complete Enterprise Solution

This guide explains how all components work together: Terraform infrastructure, Helm charts, ArgoCD, monitoring, sealed secrets, and GitHub Actions CI/CD.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitHub Repository                         │
│                                                                   │
│  ┌──────────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │  GitHub Actions  │  │ Helm Charts  │  │ ArgoCD Config   │   │
│  │   CI/CD Flows    │  │  (Packaged   │  │ (GitOps Apps)   │   │
│  └────────┬─────────┘  │   Apps)      │  └────────┬────────┘   │
│           │            └──────┬───────┘           │             │
│           │                   │                   │             │
│           └───────┬───────────┴───────────────────┘             │
│                   │                                              │
└───────────────────┼──────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Azure Cloud Platform                          │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Terraform Infrastructure                     │  │
│  │                                                            │  │
│  │  ┌────────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │  │
│  │  │     AKS    │  │ Database │  │ Storage  │  │ Network │  │  │
│  │  │ Cluster    │  │(Postgres)│  │ Account  │  │  Infra  │  │  │
│  │  └──────┬─────┘  └────┬─────┘  └────┬─────┘  └────────┘  │  │
│  │         │             │             │                    │  │
│  └─────────┼─────────────┼─────────────┼────────────────────┘  │
│            │             │             │                       │
│  ┌─────────┴─────────────┴─────────────┴────────────────────┐  │
│  │           Kubernetes Cluster (AKS)                       │  │
│  │                                                           │  │
│  │  ┌────────────────┐  ┌──────────────┐  ┌─────────────┐  │  │
│  │  │   ArgoCD       │  │  Sealed      │  │ Monitoring  │  │  │
│  │  │   (GitOps)     │  │  Secrets     │  │ (Prom+Gfana)│  │  │
│  │  └────────┬───────┘  └──────────────┘  └─────────────┘  │  │
│  │           │                                               │  │
│  │  ┌────────┴─────────────────────────────────────────┐   │  │
│  │  │         Applications (via Helm)                  │   │  │
│  │  │                                                   │   │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │  │
│  │  │  │Sample App│  │ Databases│  │  API     │  ...  │   │  │
│  │  │  │          │  │  Backups │  │ Services │       │   │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘       │   │  │
│  │  └───────────────────────────────────────────────────┘   │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow & Workflows

### CI/CD Pipeline

```
Developer Push → GitHub → Actions Validate → Plan → Approval → Apply
     ↓              ↓          ↓              ↓       ↓         ↓
   Code        Trigger    Lint/Format      Show    Manual   Infrastructure
   Commit      Workflows  Validate         Changes Approval  Updated
```

### GitOps Deployment

```
Git Push → ArgoCD Webhook → Detect Change → Helm Deploy → Running App
   ↓           ↓                  ↓               ↓             ↓
Manifest   ArgoCD Sees       Application       Sealed       Users
Update     New Commit        Template          Secrets      Access
                             Rendered
```

### Secrets Management

```
Create Secret → Seal with kubeseal → Commit to Git → Deployment → Unsealed
   ↓                  ↓                    ↓                ↓            ↓
Plain Text      Encrypted Text         Safe to          ArgoCD       Pod
Credential      (base64)               Commit           Applies       Env Var
```

---

## 🛠️ Component Integration Points

### 1. Terraform → Kubernetes

**What Terraform Creates:**
- AKS cluster
- Virtual network and subnets
- Storage accounts
- Databases
- Key Vault

**How Kubernetes Accesses Them:**
```
Terraform Outputs
    ↓
kubeconfig (downloaded)
    ↓
kubectl connects to AKS
    ↓
Helm charts deploy to cluster
```

### 2. GitHub Actions → Terraform

**Workflow Triggers:**
- Pull request with `*.tf` changes → Validate + Plan
- Merge to main → Apply to production
- Manual trigger → Deploy to staging

**Action Steps:**
```
1. Checkout code
2. Setup Terraform
3. Validate syntax
4. Run TFLint
5. Generate plan
6. Comment with results
7. (On merge) Apply changes
```

### 3. Helm → Kubernetes

**Deployment Chain:**
```
helm/sample-app/
    ├── Chart.yaml (metadata)
    ├── values.yaml (configuration)
    └── templates/ (Kubernetes manifests)
         ├── deployment.yaml
         ├── service.yaml
         ├── hpa.yaml
         └── ...
         ↓
helm install → Rendered YAML → kubectl apply → Running Pods
```

### 4. ArgoCD → Git → Kubernetes

**GitOps Workflow:**
```
Developer → Git Push → ArgoCD Webhook → Read from Git → Compare → Apply
    ↓          ↓            ↓              ↓              ↓        ↓
Feature   New Commit    Triggered       Fetch Latest   Check    Update
Update    in Main       Immediately     Helm Values    Diffs    Cluster
```

### 5. Sealed Secrets → Git → Kubernetes

**Secret Protection:**
```
Secret (plain text)
    ↓
kubeseal encrypt
    ↓
SealedSecret (encrypted YAML)
    ↓
Commit to Git (safe)
    ↓
ArgoCD detects change
    ↓
Apply SealedSecret to cluster
    ↓
Sealed Secrets Controller unseals
    ↓
Secret available to pods
```

### 6. Monitoring → Prometheus → Grafana

**Data Collection:**
```
Applications (metrics)
    ↓
Prometheus Scraper
    ↓
Time-Series Database
    ↓
Grafana Dashboard
    ↓
Alerts on Thresholds
```

---

## 📋 Step-by-Step Integration

### Phase 1: Infrastructure Setup

```bash
# 1. Deploy infrastructure with Terraform
terraform init
terraform plan -var-file=environments/prod/terraform.tfvars -out=tfplan
terraform apply tfplan

# Output values:
# - AKS cluster name
# - Kubernetes endpoint
# - Database credentials (in Key Vault)
```

### Phase 2: Kubernetes Access

```bash
# 2. Get kubeconfig
az aks get-credentials --resource-group RG --name CLUSTER

# 3. Verify access
kubectl get nodes  # Should show AKS nodes
```

### Phase 3: Helm Chart Repositories

```bash
# 4. Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add argoproj https://argoproj.github.io/argo-helm
helm repo add sealed-secrets-community https://sealed-secrets-community.github.io/sealed-secrets
helm repo update
```

### Phase 4: Deploy Supporting Infrastructure

```bash
# 5. Deploy Sealed Secrets (before ArgoCD)
helm install sealed-secrets sealed-secrets-community/sealed-secrets \
  --namespace kube-system

# 6. Deploy ArgoCD
helm install argocd argoproj/argo-cd \
  --namespace argocd \
  --values helm/argocd/values.yaml

# 7. Deploy Monitoring
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values helm/monitoring/values.yaml
```

### Phase 5: Configure GitOps

```bash
# 8. Create ArgoCD Applications
kubectl apply -f argocd/apps/sample-app.yaml

# Now argocd watches Git for changes and auto-deploys
```

### Phase 6: Setup GitHub Actions

```bash
# 9. Add GitHub Secrets
gh secret set AZURE_CLIENT_ID --body "YOUR_CLIENT_ID"
gh secret set AZURE_CLIENT_SECRET --body "YOUR_SECRET"
gh secret set AZURE_SUBSCRIPTION_ID --body "YOUR_SUBSCRIPTION"
gh secret set AZURE_TENANT_ID --body "YOUR_TENANT"
gh secret set ACR_USERNAME --body "YOUR_ACR_USERNAME"
gh secret set ACR_PASSWORD --body "YOUR_ACR_PASSWORD"

# 10. Push to GitHub - Actions automatically trigger
git push origin main
```

---

## 🔌 Configuration Points

### 1. Terraform Variables

**File**: `terraform.tfvars`

```hcl
azure_subscription_id = "xxxx-xxxx-xxxx"
company_name = "mycompany"
environment = "prod"
location = "East US"
```

### 2. Helm Values

**Files**: `helm/*/values.yaml`

Each chart has configurable values:

```yaml
# helm/sample-app/values.yaml
image:
  repository: myregistry/sample-app
  tag: "1.0.0"
resources:
  requests:
    cpu: 100m
    memory: 256Mi
```

### 3. ArgoCD Applications

**File**: `argocd/apps/sample-app.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app
spec:
  source:
    repoURL: https://github.com/your-org/apps
    path: helm/sample-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 4. GitHub Actions Secrets

**Configure in GitHub**:
```
Settings → Secrets → New Repository Secret

AZURE_CLIENT_ID=xxx
AZURE_CLIENT_SECRET=xxx
AZURE_SUBSCRIPTION_ID=xxx
AZURE_TENANT_ID=xxx
ACR_LOGIN_SERVER=xxx
ACR_USERNAME=xxx
ACR_PASSWORD=xxx
SLACK_WEBHOOK_URL=xxx (optional)
```

---

## 🔐 Security Integration

### Secret Flow

1. **Create Secret**
   ```bash
   kubectl create secret generic db-creds \
     --from-literal=user=admin \
     --from-literal=pass=secret123
   ```

2. **Seal It**
   ```bash
   kubectl get secret db-creds -o yaml | kubeseal > sealed-secret.yaml
   ```

3. **Commit to Git**
   ```bash
   git add sealed-secret.yaml
   git commit -m "Add sealed database credentials"
   git push
   ```

4. **ArgoCD Applies It**
   - ArgoCD detects the SealedSecret
   - Applies to cluster
   - Sealed Secrets controller unseals it
   - Secret becomes available to pods

### RBAC Integration

```yaml
# ArgoCD service account needs permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: argocd-admin
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```

---

## 🚀 Deployment Scenarios

### Scenario 1: Deploy New Application

```
1. Developer creates Helm chart in helm/myapp/
2. Developer creates ArgoCD Application in argocd/apps/myapp.yaml
3. Developer commits and pushes to Git
4. GitHub Actions validates the Helm chart
5. Merge to main
6. GitHub Actions creates deployment approval
7. ArgoCD detects new Application and syncs
8. Helm deploys application to cluster
```

### Scenario 2: Update Infrastructure

```
1. Developer modifies Terraform files (main.tf, variables.tf)
2. Creates pull request
3. GitHub Actions runs:
   - terraform validate
   - terraform plan
   - Comments with plan on PR
4. Code review and approval
5. Merge to main
6. GitHub Actions:
   - Applies Terraform changes
   - Notifies Slack
7. Infrastructure updated in Azure
```

### Scenario 3: Update Monitoring Rules

```
1. Developer updates helm/monitoring/values.yaml
2. Commits and pushes
3. GitHub Actions validates Helm chart
4. ArgoCD detects change
5. Helm re-deploys monitoring stack with new rules
6. Prometheus starts using new alert rules
```

---

## 📊 Monitoring Integration

### Metrics Collection

```
Kubernetes Pods
    ↓ (metrics exposed on :8080)
Prometheus Scraper (every 30s)
    ↓
Prometheus Time-Series DB
    ↓
Grafana Dashboards
    ↓
Alert Rules
    ↓
AlertManager
    ↓
Slack/PagerDuty Notifications
```

### Pre-built Dashboards

- Kubernetes Cluster Overview
- Kubernetes Pods
- Node Exporter
- Application Performance

---

## 🔍 Troubleshooting Integration

### Common Issues

**Issue**: ArgoCD not deploying changes
```bash
# Check ArgoCD sync status
kubectl get application -n argocd
kubectl describe application myapp -n argocd

# Manual sync
argocd app sync myapp
```

**Issue**: Sealed Secret not unsealing
```bash
# Check sealed-secrets controller
kubectl get pods -n kube-system | grep sealed

# Verify key exists
kubectl get sealedsecrets.bitnami.com -A
```

**Issue**: GitHub Actions deployment failing
```bash
# Check Azure credentials
az account show

# Check Terraform state
terraform state list
```

---

## 📚 Integration Checklist

- [ ] Terraform infrastructure deployed
- [ ] AKS cluster accessible with kubectl
- [ ] Helm repositories added
- [ ] Sealed Secrets deployed
- [ ] ArgoCD deployed and accessible
- [ ] Monitoring (Prometheus + Grafana) running
- [ ] Sample application deployed via ArgoCD
- [ ] GitHub Actions secrets configured
- [ ] GitHub Actions workflows passing
- [ ] Grafana dashboards visible
- [ ] Alerts configured
- [ ] DNS records updated for URLs
- [ ] SSL/TLS certificates configured
- [ ] Backup policies created
- [ ] Team members have access

---

## 📖 Related Documentation

- **Helm Guide**: `docs/HELM_GUIDE.md` - Helm chart development
- **ArgoCD Guide**: `docs/ARGOCD_GUIDE.md` - GitOps deployment
- **Monitoring Guide**: `docs/MONITORING_GUIDE.md` - Prometheus + Grafana
- **Complete Setup**: `docs/COMPLETE_SETUP_GUIDE.md` - Full deployment walkthrough
- **Quick Reference**: `QUICK_REFERENCE.md` - Common commands

---

**Your complete enterprise solution is now integrated and ready for production! 🚀**
