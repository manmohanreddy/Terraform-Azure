# Azure Terraform Backend Setup Script
# This script creates the Azure Storage Account for storing Terraform state

param(
    [string]$ResourceGroup = "terraform-state-rg",
    [string]$StorageAccountName = "tfstatestg",
    [string]$ContainerName = "tfstate",
    [string]$Location = "East US"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Terraform Backend Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if logged in
Write-Host "Checking Azure authentication..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    Write-Host "✓ Logged in as: $($context.Account.Id)" -ForegroundColor Green
}
catch {
    Write-Host "✗ Not authenticated to Azure" -ForegroundColor Red
    Write-Host "Please run: az login" -ForegroundColor Yellow
    exit 1
}

# Create Resource Group
Write-Host ""
Write-Host "Creating resource group: $ResourceGroup" -ForegroundColor Yellow
try {
    $rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
    if ($rg) {
        Write-Host "✓ Resource group already exists" -ForegroundColor Green
    }
    else {
        New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
        Write-Host "✓ Resource group created" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Failed to create resource group: $_" -ForegroundColor Red
    exit 1
}

# Create Storage Account
Write-Host ""
Write-Host "Creating storage account: $StorageAccountName" -ForegroundColor Yellow
try {
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName -ErrorAction SilentlyContinue
    if ($storageAccount) {
        Write-Host "✓ Storage account already exists" -ForegroundColor Green
    }
    else {
        New-AzStorageAccount `
            -ResourceGroupName $ResourceGroup `
            -Name $StorageAccountName `
            -SkuName "Standard_LRS" `
            -Location $Location `
            -Kind "StorageV2" | Out-Null
        Write-Host "✓ Storage account created" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Failed to create storage account: $_" -ForegroundColor Red
    exit 1
}

# Get Storage Account Context
Write-Host ""
Write-Host "Getting storage account context..." -ForegroundColor Yellow
try {
    $storageContext = (Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName).Context
    Write-Host "✓ Storage context retrieved" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to get storage context: $_" -ForegroundColor Red
    exit 1
}

# Create Container
Write-Host ""
Write-Host "Creating storage container: $ContainerName" -ForegroundColor Yellow
try {
    $container = Get-AzStorageContainer -Name $ContainerName -Context $storageContext -ErrorAction SilentlyContinue
    if ($container) {
        Write-Host "✓ Container already exists" -ForegroundColor Green
    }
    else {
        New-AzStorageContainer -Name $ContainerName -Context $storageContext | Out-Null
        Write-Host "✓ Container created" -ForegroundColor Green
    }
}
catch {
    Write-Host "✗ Failed to create container: $_" -ForegroundColor Red
    exit 1
}

# Enable Versioning
Write-Host ""
Write-Host "Enabling blob versioning..." -ForegroundColor Yellow
try {
    Update-AzStorageBlobServiceProperty `
        -ResourceGroupName $ResourceGroup `
        -StorageAccountName $StorageAccountName `
        -IsVersioningEnabled $true | Out-Null
    Write-Host "✓ Blob versioning enabled" -ForegroundColor Green
}
catch {
    Write-Host "✗ Failed to enable versioning: $_" -ForegroundColor Red
    exit 1
}

# Success Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Backend Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend Configuration:" -ForegroundColor Cyan
Write-Host "  Resource Group:     $ResourceGroup" -ForegroundColor White
Write-Host "  Storage Account:    $StorageAccountName" -ForegroundColor White
Write-Host "  Container:          $ContainerName" -ForegroundColor White
Write-Host "  Location:           $Location" -ForegroundColor White
Write-Host ""
Write-Host "Your backend.tf is already configured." -ForegroundColor Green
Write-Host "Run 'terraform init' to initialize Terraform." -ForegroundColor Yellow
