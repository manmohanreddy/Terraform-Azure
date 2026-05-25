terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestg"
    container_name       = "tfstate"
    key                  = "azure-enterprise.tfstate"
    use_azuread_auth     = true
  }
}
