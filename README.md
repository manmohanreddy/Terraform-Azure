# Azure Enterprise Infrastructure as Code

This repository contains a complete, production-ready Terraform configuration for deploying a scalable, secure enterprise infrastructure on Microsoft Azure, including Kubernetes (AKS), networking, databases, and DevOps pipelines.

## 📋 What's Included

- **Azure Kubernetes Service (AKS)** - Fully configured managed Kubernetes cluster
- **Virtual Networking** - VNets, subnets, and network security groups (NSGs)
- **Database Services** - PostgreSQL, MySQL, and Azure SQL options
- **Storage & CDN** - Blob storage, file shares, and Azure CDN
- **Monitoring & Logging** - Application Insights, Log Analytics, Azure Monitor
- **CI/CD Ready** - Integration with GitHub Actions, Azure DevOps
- **Security** - Azure Key Vault, managed identities, RBAC
- **Load Balancing** - Application Gateway, Azure Load Balancer
- **DNS & SSL** - Azure DNS, automated certificate management

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
├── main.tf              # Root module configuration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable assignments (environment-specific)
└── terraform.lock.hcl   # Dependency lock file
```

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

## 🚢 Deploying Applications to AKS

Applications can be deployed to the Kubernetes cluster using:
```bash
kubectl apply -f deployments/
```

See `kubernetes/` directory for example deployments and best practices.

## 📖 Best Practices Implemented

- **Modular Design** - Reusable components across environments
- **DRY Principle** - No configuration duplication
- **Version Control** - All code and state tracked in Git
- **Consistent Naming** - Descriptive, organized resource names
- **Tagging Strategy** - All resources tagged for organization and cost tracking
- **Security First** - Key Vault, RBAC, encryption enabled
- **High Availability** - Multi-zone deployments
- **Cost Optimization** - Auto-scaling and right-sizing

---

**Last Updated:** May 2026
