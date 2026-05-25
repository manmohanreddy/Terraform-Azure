# Complete Setup Guide: Enterprise Azure Infrastructure from Scratch

This is a comprehensive, detailed guide to set up a complete company infrastructure in Microsoft Azure using this Terraform repository. By the end, you'll have a production-ready Kubernetes cluster with databases, monitoring, and security fully configured.

**Estimated Time**: 2-3 hours (depending on Azure deployment times)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Account & Subscription Setup (15 minutes)](#phase-1-account--subscription-setup)
3. [Phase 2: Local Environment Setup (20 minutes)](#phase-2-local-environment-setup)
4. [Phase 3: Azure Authentication (10 minutes)](#phase-3-azure-authentication)
5. [Phase 4: Terraform Backend Setup (15 minutes)](#phase-4-terraform-backend-setup)
6. [Phase 5: Configure Terraform Variables (15 minutes)](#phase-5-configure-terraform-variables)
7. [Phase 6: Deploy Infrastructure (45 minutes)](#phase-6-deploy-infrastructure)
8. [Phase 7: Configure Kubernetes (20 minutes)](#phase-7-configure-kubernetes)
9. [Phase 8: Deploy Your First Application (20 minutes)](#phase-8-deploy-your-first-application)
10. [Phase 9: Verify Everything Works (15 minutes)](#phase-9-verify-everything-works)
11. [Phase 10: Monitoring & Management (15 minutes)](#phase-10-monitoring--management)

---

## Prerequisites

### Knowledge Requirements
- Basic Azure understanding (what is a subscription, resource group, etc.)
- Basic command line/terminal usage
- Basic understanding of Docker and containers
- Basic Kubernetes concepts (optional, we'll explain)

### Hardware Requirements
- Windows, macOS, or Linux machine
- 8GB+ RAM
- 5GB free disk space
- Stable internet connection

### Account Requirements
- Microsoft Azure account (Free or paid)
- If using Free tier: Azure gives you $200 credit and free services for 12 months

---

## Phase 1: Account & Subscription Setup

### Step 1.1: Create Azure Account

1. Go to **https://azure.microsoft.com/en-us/free/**
2. Click "Start free"
3. Sign in with Microsoft account (or create one)
4. Follow the signup process:
   - Verify email and phone
   - Add payment method (required for free account verification)
   - Agree to terms

**What you'll get:**
- $200 free credit for 30 days
- 12 months of free services
- Unlimited pay-as-you-go after credit expires

### Step 1.2: Get Your Subscription ID

Once your account is created:

1. Go to **Azure Portal** (https://portal.azure.com)
2. Search for "**Subscriptions**" in the top search bar
3. Click on your subscription
4. Copy the **Subscription ID** (looks like: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

```
💾 Save this! You'll need it later.
Subscription ID: _________________________
```

### Step 1.3: Note Your Tenant ID

In the same Subscriptions page:
1. Click on your subscription
2. Look for "**Tenant ID**" or "**Directory ID**" in the details

```
💾 Save this too!
Tenant ID: _________________________
```

---

## Phase 2: Local Environment Setup

### Step 2.1: Install Required Tools

Choose your operating system:

#### Windows

**Option A: Using PowerShell (Recommended)**

Open PowerShell as Administrator and run:

```powershell
# Install Chocolatey (package manager)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Close and reopen PowerShell as Administrator, then:

# Install required tools
choco install terraform -y
choco install azure-cli -y
choco install kubernetes-cli -y
choco install docker-desktop -y
choco install git -y

# Verify installations
terraform version
az version
kubectl version --client
docker --version
git --version
```

**Option B: Manual Installation**

Download and install each tool:

1. **Terraform** (https://www.terraform.io/downloads.html)
   - Download for Windows
   - Extract to `C:\Program Files\Terraform`
   - Add to PATH

2. **Azure CLI** (https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows)
   - Download MSI installer
   - Run installer

3. **kubectl** (https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/)
   - Download binary
   - Add to PATH

4. **Git** (https://git-scm.com/download/win)
   - Download and install

5. **Docker Desktop** (https://www.docker.com/products/docker-desktop)
   - Download and install

#### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install terraform
brew install azure-cli
brew install kubectl
brew install docker
brew install git

# Verify
terraform version
az version
kubectl version --client
```

#### Linux (Ubuntu/Debian)

```bash
# Update package manager
sudo apt-get update

# Install tools
sudo apt-get install -y curl
curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
sudo apt-get install -y kubectl
sudo apt-get install -y docker.io
sudo apt-get install -y git

# Add user to docker group
sudo usermod -aG docker $USER

# Verify
terraform version
az version
kubectl version --client
```

### Step 2.2: Verify All Tools Are Installed

Open terminal/PowerShell and run:

```bash
terraform version      # Should show: Terraform v1.5.0 or higher
az version            # Should show: azure-cli version
kubectl version --client  # Should show: Client Version
docker --version      # Should show: Docker version
git --version        # Should show: git version
```

If any tool is missing, install it before continuing.

### Step 2.3: Clone the Repository

```bash
# Choose a location for the repository
cd C:\Users\YourUsername\Documents    # Windows
# OR
cd ~/Projects                           # macOS/Linux

# Clone the repository
git clone https://github.com/manmohanreddy/Terraform-Azure.git
cd Terraform-Azure

# Verify you're in the right directory
ls    # or 'dir' on Windows
# Should show: README.md, main.tf, modules/, docs/, etc.
```

---

## Phase 3: Azure Authentication

### Step 3.1: Login to Azure via CLI

Open terminal/PowerShell and run:

```bash
az login
```

This will:
1. Open your browser to login.microsoft.com
2. Ask you to login with your Azure account
3. Show your subscriptions in the terminal

### Step 3.2: Set Your Subscription

```bash
# List all subscriptions
az account list --output table

# Set the default subscription (replace with your subscription ID)
az account set --subscription "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Verify it's set
az account show
# Should display your subscription details
```

### Step 3.3: Verify Permissions

Check if you have the right permissions:

```bash
# Check your current role
az role assignment list --assignee $(az account show --query "user.name" -o tsv)
```

You should see a role like **"Contributor"** or **"Owner"**. If you only have "Reader", ask your Azure admin for elevated permissions.

---

## Phase 4: Terraform Backend Setup

The backend stores your infrastructure state file securely in Azure Storage.

### Step 4.1: Understand Backend Purpose

The Terraform state file is a JSON file that tracks all your Azure resources. You need to:
- Store it remotely (not locally) for team collaboration
- Keep it secure (encrypted)
- Back it up automatically

### Step 4.2: Run Backend Setup Script

Navigate to your repository and run the setup script:

#### On Windows (PowerShell):

```powershell
cd C:\Users\YourUsername\Documents\Terraform-Azure

# Run setup script
.\scripts\setup-backend.ps1

# Output should look like:
# ========================================
# Terraform Backend Setup
# ========================================
# ✓ Logged in as: your.email@company.com
# ✓ Resource group created
# ✓ Storage account created
# ✓ Container created
# ✓ Blob versioning enabled
# Backend Setup Complete!
```

#### On macOS/Linux:

```bash
cd ~/Projects/Terraform-Azure

# Make script executable
chmod +x scripts/setup-backend.sh

# Run setup script
./scripts/setup-backend.sh

# Output should be same as Windows
```

### Step 4.3: Verify Backend Setup

```bash
# Check the storage account was created
az storage account list --output table

# Should show your storage account "tfstatestg" in the output
```

**What was created:**
- Resource Group: `terraform-state-rg`
- Storage Account: `tfstatestg`
- Container: `tfstate` (stores your state file)

---

## Phase 5: Configure Terraform Variables

### Step 5.1: Copy Example Configuration

```bash
cd c:\projects\Terraform-Azure    # or your repository directory

# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Or on Windows:
copy terraform.tfvars.example terraform.tfvars
```

### Step 5.2: Edit Configuration File

Open `terraform.tfvars` in your text editor and update these values:

```hcl
# ⚠️ CRITICAL - Update these values!

# Your Azure Subscription ID (saved earlier)
azure_subscription_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Your company name (no spaces, lowercase recommended)
company_name = "acmecorp"    # Change this!

# Project name
project_name = "enterprise"

# Azure region (choose closest to your users)
location = "East US"    # Options: East US, West US, North Europe, Southeast Asia, etc.

# Location short code
location_short = "eus"  # eus=East US, wus=West US, neu=North Europe, etc.

# Rest of configuration is pre-filled and can stay as-is
```

### Step 5.3: Understanding Environment Configs

This setup supports **3 environments**:

**Development** (`environments/dev/`):
- Smaller cluster (2-5 nodes)
- Minimal monitoring (7 day logs)
- Cost-optimized
- No resource locks (can delete resources)

**Staging** (`environments/staging/`):
- Medium cluster (3-8 nodes)
- Full monitoring (14 day logs)
- Production-like setup
- Light resource locks

**Production** (`environments/prod/`):
- Large cluster (5-20 nodes)
- Maximum monitoring (30 day logs)
- Premium resources
- Full resource locks (prevent accidents)

### Step 5.4: Choose Your First Environment

For your **first deployment**, we'll use **DEV** (faster, cheaper):

```bash
# Copy dev config as your main config
copy environments/dev/terraform.tfvars terraform.tfvars

# Now edit terraform.tfvars to update:
# - azure_subscription_id
# - company_name
# - location (if needed)
```

### Step 5.5: Understand Key Variables

Here are important variables you can customize:

```hcl
# Kubernetes version (check available: az aks get-versions --location "East US")
kubernetes_version = "1.29"

# Node pool sizing
node_pool_config = {
  initial_count       = 2      # Start with 2 nodes
  min_count          = 2      # Minimum during auto-scale
  max_count          = 5      # Maximum during auto-scale
  vm_size            = "Standard_D2s_v3"  # 2 CPU, 8GB RAM
  enable_auto_scaling = true
}

# Database options
enable_postgresql   = true    # Include PostgreSQL
enable_mysql        = false   # Skip MySQL for now

# Monitoring
log_analytics_retention_days = 7   # Dev: keep 7 days of logs

# Resource protection
resource_locks_enabled = false     # Dev: no locks (can delete)
```

Save your `terraform.tfvars` file.

---

## Phase 6: Deploy Infrastructure

This is where the magic happens! All your Azure resources will be created.

### Step 6.1: Initialize Terraform

```bash
cd c:\projects\Terraform-Azure

# Initialize - downloads providers and modules
terraform init

# Output should end with:
# Terraform has been successfully configured!
```

### Step 6.2: Validate Configuration

```bash
# Check for syntax errors
terraform validate

# Should output:
# Success! The configuration is valid.
```

### Step 6.3: Format Code (Best Practice)

```bash
# Auto-format all Terraform files
terraform fmt -recursive

# This ensures consistent formatting
```

### Step 6.4: Review What Will Be Created

```bash
# Generate a plan - shows exactly what will be created
terraform plan -out=tfplan

# This will take 30-60 seconds and show:
# Plan: XX to add, 0 to change, 0 to destroy.

# Review the plan to ensure it looks correct
terraform show tfplan | head -50
```

**What the plan shows you:**
- All resources that will be created
- All properties for each resource
- Total number of changes (should say "Plan: XX to add")

### Step 6.5: Apply the Plan (Deploy!)

```bash
# Apply the configuration - this creates real Azure resources!
terraform apply tfplan

# This will take 30-45 minutes:
# - Creating virtual networks (2 min)
# - Creating AKS cluster (25 min) - this takes longest
# - Creating databases (8 min)
# - Creating storage (3 min)
# - Creating monitoring (2 min)

# While waiting, you can monitor progress in Azure Portal:
# Home > Resource Groups > <your-company>-enterprise-eus-dev-rg
```

### Step 6.6: Verify Deployment Success

Once deployment completes, you'll see:

```
Apply complete! Resources: XX added, 0 changed, 0 destroyed.

Outputs:
resource_group_name = "acmecorp-enterprise-eus-dev-rg"
kubernetes_cluster_name = "acmecorp-enterprise-eus-dev-aks"
... (more outputs)
```

Save these outputs! They contain important information.

### Step 6.7: Check Azure Portal

Verify resources were created:

1. Go to **Azure Portal** (https://portal.azure.com)
2. Search for "**Resource Groups**"
3. Look for a group named like: `<company>-enterprise-<location>-<env>-rg`
4. Click it to see all resources created:

```
Expected resources:
✓ Virtual Network
✓ Subnets (3)
✓ Network Security Groups
✓ Kubernetes Cluster (AKS)
✓ PostgreSQL Server
✓ Storage Account
✓ Log Analytics Workspace
✓ Application Insights
✓ Application Gateway
✓ Key Vault
```

All should show "Provisioning succeeded" or "Ready".

---

## Phase 7: Configure Kubernetes

Now we need to connect kubectl to your AKS cluster.

### Step 7.1: Get Kubeconfig Credentials

```bash
# Get the credentials from terraform outputs
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)

# Configure kubectl
az aks get-credentials \
  --resource-group $RESOURCE_GROUP \
  --name $CLUSTER_NAME \
  --overwrite-existing

# Output: Merged "acmecorp-enterprise-eus-dev-aks" as current context in /home/user/.kube/config
```

This downloads your cluster credentials to `~/.kube/config` so kubectl can access your cluster.

### Step 7.2: Verify Kubectl Connection

```bash
# Test connection to cluster
kubectl cluster-info

# Output:
# Kubernetes control plane is running at https://xxx.xxx.xxx.xxx:443
# CoreDNS is running at https://xxx.xxx.xxx.xxx:443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# List nodes
kubectl get nodes

# Output should show your 2-3 nodes:
# NAME                                STATUS   ROLES   AGE   VERSION
# aks-default-12345678-vmss000000     Ready    agent   2m    v1.29.0
# aks-default-12345678-vmss000001     Ready    agent   2m    v1.29.0
```

### Step 7.3: Explore Your Cluster

```bash
# Check all pods in the system namespace
kubectl get pods -n kube-system

# Should show system pods like:
# coredns
# kube-proxy
# calico-node
# metrics-server
# etc.

# Get cluster information
kubectl cluster-info dump | head -50

# Check resource usage
kubectl top nodes

# Output shows CPU and memory usage
```

### Step 7.4: Create Your First Namespace

Namespaces isolate applications from each other:

```bash
# Create namespace for your first app
kubectl create namespace myapp

# Verify
kubectl get namespaces

# Output:
# NAME              STATUS   AGE
# default           Active   5m
# kube-system       Active   5m
# kube-public       Active   5m
# myapp             Active   5s
```

### Step 7.5: Create Secrets for Database

Store database credentials securely:

```bash
# Get PostgreSQL password from Key Vault
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)

az keyvault secret show \
  --vault-name $KEY_VAULT_NAME \
  --name postgresql-admin-password \
  --query value -o tsv

# Copy the output (this is your database password)

# Create Kubernetes secret
kubectl create secret generic db-credentials \
  --from-literal=username=psqladmin \
  --from-literal=password='PASTE_PASSWORD_HERE' \
  -n myapp

# Verify secret was created
kubectl get secrets -n myapp
```

---

## Phase 8: Deploy Your First Application

Let's deploy a simple web application to your Kubernetes cluster.

### Step 8.1: Create Azure Container Registry (ACR)

ACR stores your Docker images:

```bash
COMPANY_NAME="acmecorp"  # Update to your company name
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Create container registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name ${COMPANY_NAME}acr \
  --sku Basic

# Get login credentials
ACR_USERNAME=$(az acr credential show \
  --name ${COMPANY_NAME}acr \
  --query username -o tsv)

ACR_PASSWORD=$(az acr credential show \
  --name ${COMPANY_NAME}acr \
  --query "passwords[0].value" -o tsv)

# Display credentials
echo "ACR Name: ${COMPANY_NAME}acr.azurecr.io"
echo "Username: $ACR_USERNAME"
echo "Password: $ACR_PASSWORD"

# Save these for later
```

### Step 8.2: Create Docker Image

Create a simple test application. First, create a directory:

```bash
mkdir -p ~/myapp/docker
cd ~/myapp/docker
```

Create `Dockerfile`:

```dockerfile
FROM nginx:latest
RUN echo "<h1>Welcome to My App on Azure!</h1>" > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

Create `.dockerignore`:

```
.git
.gitignore
node_modules
.env
```

### Step 8.3: Build and Push Docker Image

```bash
cd ~/myapp/docker

# Login to your container registry
az acr login --name acmecorpacr  # Update to your ACR name

# Build image
docker build -t myapp:1.0 .

# Tag for ACR
docker tag myapp:1.0 acmecorpacr.azurecr.io/myapp:1.0

# Push to ACR
docker push acmecorpacr.azurecr.io/myapp:1.0

# Verify
az acr repository list --name acmecorpacr
# Should show: myapp
```

### Step 8.4: Create Image Pull Secret

Kubernetes needs credentials to pull images from ACR:

```bash
# Create secret for ACR
kubectl create secret docker-registry acr-secret \
  --docker-server=acmecorpacr.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=yourname@company.com \
  -n myapp

# Verify
kubectl get secrets -n myapp
```

### Step 8.5: Deploy Application

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      imagePullSecrets:
      - name: acr-secret
      containers:
      - name: myapp
        image: acmecorpacr.azurecr.io/myapp:1.0
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: myapp
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

Deploy:

```bash
# Deploy to cluster
kubectl apply -f deployment.yaml

# Watch deployment progress
kubectl rollout status deployment/myapp -n myapp

# Get service details
kubectl get svc -n myapp

# Wait for EXTERNAL-IP to appear (takes 2-3 minutes)
kubectl get svc -n myapp -w
```

### Step 8.6: Test Your Application

Once EXTERNAL-IP appears:

```bash
# Get the external IP
EXTERNAL_IP=$(kubectl get svc myapp -n myapp -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Visit: http://$EXTERNAL_IP"

# Or test from command line
curl http://$EXTERNAL_IP

# Should show:
# <h1>Welcome to My App on Azure!</h1>
```

🎉 **Your application is now running on Kubernetes!**

---

## Phase 9: Verify Everything Works

### Step 9.1: Check All Pods Are Running

```bash
# List all pods
kubectl get pods -n myapp

# Output should show:
# NAME                     READY   STATUS    RESTARTS   AGE
# myapp-5d4b8c9f7b-xxxxx   1/1     Running   0          3m
# myapp-5d4b8c9f7b-yyyyy   1/1     Running   0          3m
# myapp-5d4b8c9f7b-zzzzz   1/1     Running   0          3m

# All should be "Running"
```

### Step 9.2: Check Application Logs

```bash
# View logs from a pod
kubectl logs -n myapp deployment/myapp

# Follow logs in real-time
kubectl logs -f -n myapp deployment/myapp

# View logs from specific pod
kubectl logs -n myapp myapp-5d4b8c9f7b-xxxxx
```

### Step 9.3: Verify Database Connection

```bash
# Get PostgreSQL connection details
PSQL_HOST=$(terraform output -raw postgresql_server_fqdn)
PSQL_USER="psqladmin"

echo "PostgreSQL Server: $PSQL_HOST"

# Test connection from your machine (if psql installed)
psql -h $PSQL_HOST -U $PSQL_USER -d appdb

# If prompted for password, use the one from Key Vault
# Type: \q to exit
```

### Step 9.4: Check Storage Account

```bash
# List storage containers
STORAGE_ACCT=$(terraform output -raw storage_account_name)

az storage container list --account-name $STORAGE_ACCT --output table

# Should show:
# appdata
# backups
# logs
```

### Step 9.5: Verify Monitoring

```bash
# Get Log Analytics workspace
az monitor log-analytics workspace list -o table

# View Application Insights
az monitor app-insights component list -o table

# Check if data is flowing (takes 10 minutes after deployment)
```

### Step 9.6: View Cluster Dashboard

```bash
# Start Kubernetes dashboard
kubectl proxy

# Open browser to:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

# You can now see:
# - All resources (pods, services, deployments)
# - Resource usage
# - Pod logs
# - Events
```

---

## Phase 10: Monitoring & Management

### Step 10.1: Access Azure Portal Monitoring

1. Go to **Azure Portal** (https://portal.azure.com)
2. Search for "**Log Analytics Workspaces**"
3. Click your workspace (named like: `acmecorp-enterprise-eus-dev-law`)
4. On left menu, click "**Logs**"
5. Run queries to view logs:

```kusto
// View all logs from past hour
search *
| where TimeGenerated > ago(1h)
| take 100

// View AKS cluster events
KubeNodeInventory
| where TimeGenerated > ago(1h)
| project TimeGenerated, Computer, Status, KubeVersion

// View pod events
KubePodInventory
| where TimeGenerated > ago(1h)
| project TimeGenerated, PodName, Namespace, PodStatus
```

### Step 10.2: Setup Alerts

Create alerts for important events:

```bash
# View existing alerts
az monitor metrics alert list -o table

# Create alert for high CPU usage
az monitor metrics alert create \
  --name "HighCPUAlert" \
  --resource-group $(terraform output -raw resource_group_name) \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/YOUR_RG/providers/Microsoft.ContainerService/managedClusters/YOUR_CLUSTER" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

### Step 10.3: View Application Insights

1. Go to **Azure Portal**
2. Search "**Application Insights**"
3. Click your App Insights instance
4. On left menu, explore:
   - **Live Metrics**: Real-time data
   - **Application Map**: Service dependencies
   - **Performance**: Response times
   - **Failures**: Errors and exceptions
   - **Users**: User analytics

### Step 10.4: Check Kubernetes Metrics

```bash
# View resource usage
kubectl top nodes
kubectl top pods -n myapp

# View HPA status (auto-scaling)
kubectl get hpa -n myapp

# View resource requests vs limits
kubectl describe node

# Check node conditions
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory,READY:.status.conditions[?(@.type=='Ready')].status
```

### Step 10.5: Setup Cost Monitoring

Azure automatically tracks costs. View them:

1. Go to **Azure Portal**
2. Search "**Cost Management + Billing**"
3. Click "**Cost Analysis**"
4. View your spending:
   - By resource type
   - By service
   - Forecast (estimated spending)

**Cost Optimization Tips:**
- Set budget alerts (alert at $100, $500, etc.)
- Review unused resources monthly
- Use reserved instances for predictable workloads
- Auto-shutdown non-prod environments at night

### Step 10.6: Enable Backup

Backup your data:

```bash
# PostgreSQL backups are automatic (7 days retention)
# To restore from backup:
az postgres flexible-server show \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw postgresql_server_name)

# View available backups:
az postgres flexible-server list-backups \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw postgresql_server_name)
```

---

## Common Tasks After Setup

### Scaling Your Application

```bash
# Manually scale pods
kubectl scale deployment myapp --replicas=5 -n myapp

# View autoscaler
kubectl get hpa -n myapp

# Edit autoscaling
kubectl edit hpa myapp -n myapp
# Change minReplicas and maxReplicas
```

### Update Your Application

```bash
# Build new image
docker build -t myapp:2.0 .
docker tag myapp:2.0 acmecorpacr.azurecr.io/myapp:2.0
docker push acmecorpacr.azurecr.io/myapp:2.0

# Update deployment
kubectl set image deployment/myapp myapp=acmecorpacr.azurecr.io/myapp:2.0 -n myapp

# Watch rollout
kubectl rollout status deployment/myapp -n myapp
```

### Add More Environments

To add staging/production:

```bash
# Create staging deployment
cp terraform.tfvars terraform.staging.tfvars

# Edit staging config
# Change:
# - environment = "staging"
# - node_pool_config.min_count = 3
# - node_pool_config.max_count = 8

# Deploy staging
terraform plan -var-file=terraform.staging.tfvars -out=staging.tfplan
terraform apply staging.tfplan

# Now you have dev + staging running!
```

### Increase Cluster Size

```bash
# Edit terraform.tfvars
# Change node_pool_config.max_count to larger number

# Deploy
terraform plan -out=tfplan
terraform apply tfplan

# Cluster will automatically scale up when needed
```

### Connect to Database

```bash
# Get connection string
PSQL_HOST=$(terraform output -raw postgresql_server_fqdn)
DB_USER="psqladmin"
DB_NAME="appdb"

# Connection string:
echo "postgresql://$DB_USER:PASSWORD@$PSQL_HOST:5432/$DB_NAME?sslmode=require"

# Using psql:
psql -h $PSQL_HOST -U $DB_USER -d $DB_NAME

# Using from application code (Python example):
import psycopg2
conn = psycopg2.connect(
    host="SERVER.postgres.database.azure.com",
    user="psqladmin@SERVER",
    password="password",
    database="appdb",
    sslmode="require"
)
```

---

## Troubleshooting

### kubectl shows "Unable to connect to server"

```bash
# Reconfigure credentials
az aks get-credentials --resource-group YOUR_RG --name YOUR_CLUSTER --overwrite-existing

# Verify context
kubectl config get-contexts

# Switch context if needed
kubectl config use-context YOUR_CLUSTER_NAME
```

### Application pod in "ImagePullBackOff"

```bash
# Check pull secret exists
kubectl get secrets -n myapp

# Recreate if needed
kubectl delete secret acr-secret -n myapp
kubectl create secret docker-registry acr-secret \
  --docker-server=yourregistry.azurecr.io \
  --docker-username=USERNAME \
  --docker-password=PASSWORD \
  -n myapp
```

### Terraform says "resource already exists"

```bash
# Import the existing resource
terraform import azurerm_resource_group.main /subscriptions/SUB_ID/resourceGroups/RG_NAME

# Or destroy and recreate
terraform destroy -auto-approve
terraform apply
```

### High costs in Azure billing

```bash
# Check resource usage
az monitor metrics list-definitions --resource /subscriptions/YOUR_SUB/resourceGroups/YOUR_RG --output table

# Stop unused resources
kubectl delete deployment myapp -n myapp  # Stop app
terraform destroy -auto-approve           # Destroy infrastructure
```

---

## Next Steps

Once everything is running:

1. **Setup CI/CD**: Connect GitHub Actions or Azure DevOps for automatic deployments
2. **Add SSL/TLS**: Setup HTTPS with Let's Encrypt
3. **Enable RBAC**: Control who can access your cluster
4. **Setup Backups**: Configure database backups to storage
5. **Add Monitoring**: Setup custom alerts and dashboards
6. **Scale**: Add more node pools for specialized workloads

---

## Support & Resources

### Documentation
- [Azure Kubernetes Service Docs](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Kubernetes Official Docs](https://kubernetes.io/docs/)

### Getting Help
- Check `docs/TROUBLESHOOTING.md` in this repository
- Search Azure Portal for "Help + Support"
- Check Kubernetes events: `kubectl describe pod POD_NAME -n NAMESPACE`

### Monitoring
- **Azure Portal**: Monitor resources, costs, and alerts
- **kubectl**: Monitor pods and cluster health
- **Application Insights**: Monitor application performance
- **Log Analytics**: Query logs and metrics

---

## Summary Checklist

✅ Azure account created
✅ Tools installed locally
✅ Authenticated to Azure
✅ Terraform backend setup
✅ Variables configured
✅ Infrastructure deployed (AKS, database, storage, etc.)
✅ Kubernetes configured
✅ First application deployed
✅ Monitoring setup
✅ Testing complete

🎉 **You now have a production-ready infrastructure in Azure!**

---

**Estimated Costs (Monthly)**

Using dev environment for 8 hours/day:

| Resource | Cost |
|----------|------|
| AKS (2 nodes, 2 CPUs) | ~$30 |
| PostgreSQL (Basic) | ~$20 |
| Storage Account | ~$5 |
| Application Gateway | ~$15 |
| Monitoring | ~$10 |
| **Total** | **~$80/month** |

Free tier: First month free with $200 credit

For production, costs would be ~$300-500/month depending on workload size.

---

**Document Version**: 1.0
**Last Updated**: May 2026
**Author**: Infrastructure Team
