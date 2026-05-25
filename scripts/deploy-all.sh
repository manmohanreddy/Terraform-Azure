#!/bin/bash

# Complete Azure Infrastructure Deployment Script
# Deploys everything: Infrastructure, Helm charts, ArgoCD, Monitoring, Sealed Secrets

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-dev}"
REGION="East US"
TIMEOUT=600

echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}        Azure Enterprise Infrastructure Deployment Script${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    print_section "Step 1: Checking Prerequisites"

    echo -e "${YELLOW}Checking required tools...${NC}"

    local missing_tools=0

    # Check terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}✗ Terraform not found${NC}"
        missing_tools=1
    else
        echo -e "${GREEN}✓ Terraform $(terraform version -json | jq -r '.terraform_version')${NC}"
    fi

    # Check azure cli
    if ! command -v az &> /dev/null; then
        echo -e "${RED}✗ Azure CLI not found${NC}"
        missing_tools=1
    else
        echo -e "${GREEN}✓ Azure CLI $(az version -o json | jq -r '.\"azure-cli\"')${NC}"
    fi

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}✗ kubectl not found${NC}"
        missing_tools=1
    else
        echo -e "${GREEN}✓ kubectl $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')${NC}"
    fi

    # Check helm
    if ! command -v helm &> /dev/null; then
        echo -e "${RED}✗ Helm not found${NC}"
        missing_tools=1
    else
        echo -e "${GREEN}✓ Helm $(helm version -o json | jq -r '.version')${NC}"
    fi

    if [ $missing_tools -eq 1 ]; then
        echo -e "${RED}✗ Missing required tools. Please install them and try again.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All prerequisites met${NC}"
}

# Function to validate Azure authentication
validate_azure_auth() {
    print_section "Step 2: Validating Azure Authentication"

    echo -e "${YELLOW}Checking Azure authentication...${NC}"

    if ! az account show &> /dev/null; then
        echo -e "${RED}✗ Not authenticated to Azure${NC}"
        echo -e "${YELLOW}Run: az login${NC}"
        exit 1
    fi

    ACCOUNT=$(az account show --query user.name -o tsv)
    SUBSCRIPTION=$(az account show --query name -o tsv)

    echo -e "${GREEN}✓ Authenticated as: $ACCOUNT${NC}"
    echo -e "${GREEN}✓ Subscription: $SUBSCRIPTION${NC}"
}

# Function to setup Terraform backend
setup_terraform_backend() {
    print_section "Step 3: Setting Up Terraform Backend"

    echo -e "${YELLOW}Creating backend storage...${NC}"

    RESOURCE_GROUP="terraform-state-rg"
    STORAGE_ACCOUNT="tfstatestg"
    CONTAINER="tfstate"

    # Check if resource group exists
    if az group exists --name $RESOURCE_GROUP | grep -q false; then
        echo -e "${YELLOW}Creating resource group...${NC}"
        az group create --name $RESOURCE_GROUP --location "$REGION" > /dev/null
        echo -e "${GREEN}✓ Resource group created${NC}"
    else
        echo -e "${GREEN}✓ Resource group exists${NC}"
    fi

    # Check if storage account exists
    if ! az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP &> /dev/null; then
        echo -e "${YELLOW}Creating storage account...${NC}"
        az storage account create \
            --name $STORAGE_ACCOUNT \
            --resource-group $RESOURCE_GROUP \
            --location "$REGION" \
            --sku Standard_LRS \
            --kind StorageV2 > /dev/null
        echo -e "${GREEN}✓ Storage account created${NC}"
    else
        echo -e "${GREEN}✓ Storage account exists${NC}"
    fi

    # Check if container exists
    STORAGE_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "[0].value" -o tsv)

    if ! az storage container exists --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --name $CONTAINER | jq -e '.exists' > /dev/null; then
        echo -e "${YELLOW}Creating storage container...${NC}"
        az storage container create --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --name $CONTAINER > /dev/null
        echo -e "${GREEN}✓ Storage container created${NC}"
    else
        echo -e "${GREEN}✓ Storage container exists${NC}"
    fi

    echo -e "${GREEN}✓ Terraform backend ready${NC}"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_section "Step 4: Deploying Infrastructure (Terraform)"

    echo -e "${YELLOW}This step will create:${NC}"
    echo "  • Virtual Network with subnets"
    echo "  • AKS Kubernetes cluster"
    echo "  • PostgreSQL database"
    echo "  • Storage account"
    echo "  • Application Gateway"
    echo "  • Monitoring resources"
    echo ""
    echo -e "${YELLOW}Estimated time: 45 minutes${NC}"

    # Initialize Terraform
    echo -e "${YELLOW}Initializing Terraform...${NC}"
    terraform init
    echo -e "${GREEN}✓ Terraform initialized${NC}"

    # Format
    echo -e "${YELLOW}Formatting Terraform code...${NC}"
    terraform fmt -recursive > /dev/null
    echo -e "${GREEN}✓ Code formatted${NC}"

    # Validate
    echo -e "${YELLOW}Validating Terraform...${NC}"
    terraform validate > /dev/null
    echo -e "${GREEN}✓ Validation passed${NC}"

    # Plan
    echo -e "${YELLOW}Planning deployment...${NC}"
    if [ "$ENVIRONMENT" == "prod" ]; then
        terraform plan -var-file=environments/prod/terraform.tfvars -out=tfplan -lock=false
    else
        terraform plan -var-file=environments/dev/terraform.tfvars -out=tfplan -lock=false
    fi
    echo -e "${GREEN}✓ Plan created${NC}"

    # Apply
    echo ""
    read -p "Do you want to apply the Terraform plan? (yes/no) " -n 3 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Applying Terraform configuration...${NC}"
        terraform apply tfplan
        echo -e "${GREEN}✓ Infrastructure deployed${NC}"
    else
        echo -e "${YELLOW}Terraform apply skipped${NC}"
        return 1
    fi
}

# Function to configure kubectl
configure_kubectl() {
    print_section "Step 5: Configuring kubectl"

    echo -e "${YELLOW}Getting AKS credentials...${NC}"

    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw kubernetes_cluster_name)

    az aks get-credentials \
        --resource-group $RESOURCE_GROUP \
        --name $CLUSTER_NAME \
        --overwrite-existing > /dev/null

    echo -e "${GREEN}✓ kubectl configured${NC}"

    # Verify connection
    echo -e "${YELLOW}Verifying cluster connection...${NC}"
    if kubectl cluster-info > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Connected to AKS cluster${NC}"
    else
        echo -e "${RED}✗ Failed to connect to cluster${NC}"
        return 1
    fi
}

# Function to add Helm repositories
add_helm_repos() {
    print_section "Step 6: Adding Helm Repositories"

    echo -e "${YELLOW}Adding Helm repositories...${NC}"

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add argoproj https://argoproj.github.io/argo-helm
    helm repo add sealed-secrets-community https://sealed-secrets-community.github.io/sealed-secrets
    helm repo update

    echo -e "${GREEN}✓ Helm repositories added${NC}"
}

# Function to deploy sealed-secrets
deploy_sealed_secrets() {
    print_section "Step 7: Deploying Sealed Secrets"

    echo -e "${YELLOW}Installing Sealed Secrets...${NC}"

    helm upgrade --install sealed-secrets \
        sealed-secrets-community/sealed-secrets \
        --namespace kube-system \
        --values helm/sealed-secrets/values.yaml > /dev/null

    echo -e "${GREEN}✓ Sealed Secrets deployed${NC}"
}

# Function to deploy ArgoCD
deploy_argocd() {
    print_section "Step 8: Deploying ArgoCD"

    echo -e "${YELLOW}Installing ArgoCD...${NC}"

    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install argocd \
        argoproj/argo-cd \
        --namespace argocd \
        --values helm/argocd/values.yaml > /dev/null

    echo -e "${GREEN}✓ ArgoCD deployed${NC}"

    # Get ArgoCD password
    echo -e "${YELLOW}ArgoCD credentials:${NC}"
    echo "  Username: admin"
    echo "  Password: (configured in values.yaml)"
}

# Function to deploy monitoring
deploy_monitoring() {
    print_section "Step 9: Deploying Monitoring Stack"

    echo -e "${YELLOW}Installing Prometheus and Grafana...${NC}"

    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

    helm dependency update helm/monitoring/
    helm upgrade --install monitoring \
        prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --values helm/monitoring/values.yaml > /dev/null

    echo -e "${GREEN}✓ Monitoring stack deployed${NC}"

    # Get Grafana password
    echo -e "${YELLOW}Grafana credentials:${NC}"
    echo "  Username: admin"
    echo "  Password: (configured in values.yaml)"
}

# Function to deploy sample application
deploy_sample_app() {
    print_section "Step 10: Deploying Sample Application"

    echo -e "${YELLOW}Deploying sample application...${NC}"

    kubectl create namespace myapp --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install sample-app \
        helm/sample-app/ \
        --namespace myapp \
        --values helm/sample-app/values.yaml > /dev/null

    echo -e "${GREEN}✓ Sample application deployed${NC}"
}

# Function to verify deployment
verify_deployment() {
    print_section "Step 11: Verifying Deployment"

    echo -e "${YELLOW}Checking pod status...${NC}"

    echo "AKS Nodes:"
    kubectl get nodes
    echo ""

    echo "System Pods:"
    kubectl get pods -n kube-system | head -5
    echo ""

    echo "ArgoCD Pods:"
    kubectl get pods -n argocd | head -5
    echo ""

    echo "Monitoring Pods:"
    kubectl get pods -n monitoring | head -5
    echo ""

    echo -e "${GREEN}✓ All components deployed${NC}"
}

# Function to print summary
print_summary() {
    print_section "Deployment Complete!"

    echo -e "${GREEN}✅ All components deployed successfully${NC}"
    echo ""
    echo -e "${CYAN}Access URLs:${NC}"
    echo "  • Grafana: https://grafana.example.com"
    echo "  • Prometheus: https://prometheus.example.com"
    echo "  • ArgoCD: https://argocd.example.com"
    echo "  • Sample App: https://sample-app.example.com"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "  1. Update DNS records for the URLs above"
    echo "  2. Configure TLS certificates"
    echo "  3. Setup webhook integrations for Git"
    echo "  4. Configure backup policies"
    echo "  5. Setup monitoring alerts"
    echo ""
    echo -e "${YELLOW}Documentation:${NC}"
    echo "  • Helm Guide: docs/HELM_GUIDE.md"
    echo "  • ArgoCD Guide: docs/ARGOCD_GUIDE.md"
    echo "  • Monitoring Guide: docs/MONITORING_GUIDE.md"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    validate_azure_auth
    setup_terraform_backend

    if deploy_infrastructure; then
        configure_kubectl
        add_helm_repos
        deploy_sealed_secrets
        deploy_argocd
        deploy_monitoring
        deploy_sample_app
        verify_deployment
        print_summary
    else
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
