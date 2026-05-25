# Azure Enterprise Infrastructure Setup Guide

This guide walks you through setting up a complete enterprise infrastructure on Microsoft Azure using Terraform.

## Prerequisites

### Required Tools

```bash
# Check versions
terraform version      # >= 1.5.0
az --version          # >= 2.40.0
kubectl version --client
```

### Azure Account

- Active Azure subscription
- Appropriate permissions (Owner or Contributor role)
- Azure CLI installed and configured

## Step 1: Clone the Repository

```bash
git clone https://github.com/manmohanreddy/Terraform-Azure.git
cd Terraform-Azure
```

## Step 2: Configure Azure Authentication

### Option A: Using Azure CLI (Recommended for Development)

```bash
# Login to Azure
az login

# Set the subscription
az account set --subscription "your-subscription-id"

# Verify
az account show
```

### Option B: Using Service Principal (Recommended for CI/CD)

```bash
# Create a service principal
az ad sp create-for-rbac --name "terraform-sp" --role Contributor

# Export environment variables
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<subscription>"
export ARM_TENANT_ID="<tenant>"
```

## Step 3: Setup Remote State Storage

Before deploying, you need to set up a backend for storing Terraform state.

```bash
# Create resource group for state
az group create --name terraform-state-rg --location "East US"

# Create storage account
az storage account create \
  --name tfstatestg \
  --resource-group terraform-state-rg \
  --location "East US" \
  --sku Standard_LRS \
  --kind StorageV2

# Create container
az storage container create \
  --name tfstate \
  --account-name tfstatestg

# Enable versioning
az storage account blob-service-properties update \
  --account-name tfstatestg \
  --enable-versioning true
```

Or use the helper script:

```bash
./scripts/setup-backend.sh
```

## Step 4: Configure Terraform Variables

Choose your environment (dev, staging, or prod):

```bash
# Copy the example file
cp environments/dev/terraform.tfvars terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### Key Variables to Update

```hcl
azure_subscription_id = "your-subscription-id"
company_name          = "your-company"
project_name          = "your-project"
location              = "East US"  # or your preferred region
```

## Step 5: Initialize Terraform

```bash
# Initialize the working directory
terraform init

# Verify initialization
terraform validate
```

## Step 6: Plan the Deployment

```bash
# Generate and review the plan
terraform plan -out=tfplan

# Save the plan output for review
terraform show tfplan > tfplan.txt
```

Review the plan carefully to ensure all resources are as expected.

## Step 7: Apply the Configuration

```bash
# Apply the plan
terraform apply tfplan

# This will take 15-30 minutes depending on your region
```

Wait for the deployment to complete. You'll see output values once done.

## Step 8: Configure kubectl

Once AKS is deployed, configure your local kubectl:

```bash
# Get credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw kubernetes_cluster_name) \
  --overwrite-existing

# Verify connection
kubectl get nodes
kubectl get pods -A
```

## Step 9: Access Kubernetes Cluster

### View Cluster Info

```bash
# Get cluster information
kubectl cluster-info
kubectl get all -A

# View nodes
kubectl get nodes -o wide

# View resource usage
kubectl top nodes
kubectl top pods -A
```

### Deploy Your First Application

```bash
# Create a namespace
kubectl create namespace myapp

# Deploy a sample application
kubectl create deployment nginx --image=nginx -n myapp
kubectl expose deployment nginx --port=80 -n myapp

# Check deployment
kubectl get all -n myapp
```

## Step 10: Verify Deployment

### Check Azure Resources

```bash
# List all resources in the resource group
az resource list --resource-group $(terraform output -raw resource_group_name) --output table

# Check AKS cluster status
az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw kubernetes_cluster_name)

# Check PostgreSQL
az postgres flexible-server list --resource-group $(terraform output -raw resource_group_name)
```

### Access Monitoring

```bash
# View AKS logs
kubectl logs -n kube-system -l component=kubelet

# View events
kubectl get events -A

# Check monitoring workspace
az monitor log-analytics workspace list \
  --resource-group $(terraform output -raw resource_group_name)
```

## Troubleshooting

### Authentication Issues

```bash
# Verify Azure login
az account show

# Check credentials
echo $ARM_SUBSCRIPTION_ID

# Re-authenticate if needed
az login --use-device-code
```

### Terraform State Issues

```bash
# Check current state
terraform state list

# Show specific resource
terraform state show azurerm_kubernetes_cluster.main

# Refresh state
terraform refresh
```

### Kubectl Connection Issues

```bash
# Reset kubeconfig
rm ~/.kube/config

# Reconfigure
az aks get-credentials --resource-group <rg> --name <cluster-name>

# Verify API server access
kubectl cluster-info dump
```

### Resource Quotas

If you hit Azure resource quotas:

```bash
# Check current usage
az vm list-usage --location "East US" -o table

# Request quota increase through Azure Portal:
# Home > Subscriptions > Usage + quotas
```

## Next Steps

1. **Deploy Applications**: See `DEPLOYMENT.md` for application deployment guide
2. **Configure CI/CD**: Set up GitHub Actions or Azure DevOps pipelines
3. **Setup Monitoring**: Configure alerts in Application Insights
4. **Enable Security**: Configure RBAC and network policies
5. **Backup Strategy**: Set up backup policies for databases

## Cleanup

To destroy all resources (WARNING: This is destructive):

```bash
# Show what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy

# Confirm when prompted
```

## Support & Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices.html)

---

For detailed architecture information, see `ARCHITECTURE.md`
For troubleshooting common issues, see `TROUBLESHOOTING.md`
