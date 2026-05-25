#!/bin/bash

# Azure Terraform Backend Setup Script
# This script creates the Azure Storage Account for storing Terraform state

set -e

# Configuration
RESOURCE_GROUP="${1:-terraform-state-rg}"
STORAGE_ACCOUNT="${2:-tfstatestg}"
CONTAINER_NAME="${3:-tfstate}"
LOCATION="${4:-East US}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo "Terraform Backend Setup"
echo "========================================${NC}"
echo ""

# Check Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI not found${NC}"
    echo -e "${YELLOW}Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli${NC}"
    exit 1
fi

# Check authentication
echo -e "${YELLOW}Checking Azure authentication...${NC}"
if az account show &> /dev/null; then
    ACCOUNT=$(az account show --query user.name -o tsv)
    echo -e "${GREEN}✓ Logged in as: $ACCOUNT${NC}"
else
    echo -e "${RED}✗ Not authenticated to Azure${NC}"
    echo -e "${YELLOW}Please run: az login${NC}"
    exit 1
fi

# Create Resource Group
echo ""
echo -e "${YELLOW}Creating resource group: $RESOURCE_GROUP${NC}"
if az group exists --name "$RESOURCE_GROUP" | grep -q true; then
    echo -e "${GREEN}✓ Resource group already exists${NC}"
else
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" > /dev/null
    echo -e "${GREEN}✓ Resource group created${NC}"
fi

# Create Storage Account
echo ""
echo -e "${YELLOW}Creating storage account: $STORAGE_ACCOUNT${NC}"
if az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo -e "${GREEN}✓ Storage account already exists${NC}"
else
    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --sku "Standard_LRS" \
        --kind "StorageV2" > /dev/null
    echo -e "${GREEN}✓ Storage account created${NC}"
fi

# Get Storage Account Key
echo ""
echo -e "${YELLOW}Retrieving storage account key...${NC}"
STORAGE_KEY=$(az storage account keys list \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[0].value" -o tsv)
echo -e "${GREEN}✓ Storage key retrieved${NC}"

# Create Container
echo ""
echo -e "${YELLOW}Creating storage container: $CONTAINER_NAME${NC}"
if az storage container exists \
    --account-name "$STORAGE_ACCOUNT" \
    --account-key "$STORAGE_KEY" \
    --name "$CONTAINER_NAME" | grep -q true; then
    echo -e "${GREEN}✓ Container already exists${NC}"
else
    az storage container create \
        --account-name "$STORAGE_ACCOUNT" \
        --account-key "$STORAGE_KEY" \
        --name "$CONTAINER_NAME" > /dev/null
    echo -e "${GREEN}✓ Container created${NC}"
fi

# Enable Versioning
echo ""
echo -e "${YELLOW}Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --enable-versioning true > /dev/null
echo -e "${GREEN}✓ Blob versioning enabled${NC}"

# Success Summary
echo ""
echo -e "${GREEN}========================================"
echo "Backend Setup Complete!"
echo "========================================${NC}"
echo ""
echo -e "${CYAN}Backend Configuration:${NC}"
echo -e "  Resource Group:     ${RESOURCE_GROUP}"
echo -e "  Storage Account:    ${STORAGE_ACCOUNT}"
echo -e "  Container:          ${CONTAINER_NAME}"
echo -e "  Location:           ${LOCATION}"
echo ""
echo -e "${GREEN}Your backend.tf is already configured.${NC}"
echo -e "${YELLOW}Run 'terraform init' to initialize Terraform.${NC}"
