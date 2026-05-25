resource "azurerm_user_assigned_identity" "aks" {
  location            = var.location
  name                = "${var.environment_prefix}-aks-identity"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.environment_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.environment_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  # Node resource group
  node_resource_group = "${var.environment_prefix}-aks-nodes-rg"

  # Network profile
  network_profile {
    network_plugin      = "azure"
    network_policy      = var.enable_network_policy ? var.network_policy : null
    dns_service_ip      = "10.1.0.10"
    service_cidr        = "10.1.0.0/16"
    outbound_type       = "loadBalancer"
    load_balancer_sku   = "standard"
    pod_cidr            = "10.244.0.0/16"
  }

  # Default node pool
  default_node_pool {
    name                = "default"
    node_count          = var.node_pool_config.initial_count
    vm_size             = var.node_pool_config.vm_size
    os_disk_size_gb     = 30
    os_disk_type        = "Managed"
    os_sku              = "Ubuntu"

    enable_auto_scaling = var.node_pool_config.enable_auto_scaling
    min_count          = var.node_pool_config.min_count
    max_count          = var.node_pool_config.max_count

    vnet_subnet_id     = var.aks_subnet_id

    node_labels        = var.node_pool_config.node_labels
    node_taints        = var.node_pool_config.node_taints

    enable_host_encryption = true

    zones = ["1", "2", "3"]

    only_critical_addons_enabled = false
  }

  # Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  # Azure AD Integration
  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = []
  }

  # RBAC
  role_based_access_control_enabled = true

  # API Server Access
  api_server_access_profile {
    authorized_ip_ranges = []
  }

  # Monitoring
  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  # Add-ons
  addon_profile {
    azure_policy {
      enabled = true
    }
  }

  # Pod Identity
  pod_identity_profile {
    enabled            = var.enable_pod_identity
    user_assigned_identities {
      enabled = true
    }
  }

  # Auto-scaler profile
  auto_scaler_profile {
    balance_similar_node_groups      = true
    empty_bulk_delete_max            = 10
    expander                         = "priority,least-waste"
    max_graceful_termination_sec     = 600
    max_node_provision_time          = "15m"
    max_total_unready_percentage     = 45
    new_pod_scale_up_delay           = "0s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
  }

  # Maintenance Window
  maintenance_window {
    allowed {
      day   = "Saturday"
      hours = [0, 4]
    }
    allowed {
      day   = "Sunday"
      hours = [0, 4]
    }
  }

  depends_on = [
    azurerm_user_assigned_identity.aks
  ]
}

# Additional Node Pool for GPU workloads (optional)
resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count                 = 0  # Set to 1 if GPU nodes needed
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_count            = 1
  vm_size               = "Standard_NC6s_v3"
  zones                 = ["1", "2"]
  node_labels = {
    workload = "gpu"
  }
  node_taints = [{
    key    = "gpu"
    value  = "true"
    effect = "NoSchedule"
  }]

  enable_auto_scaling = true
  min_count          = 1
  max_count          = 3
}

# Get current Azure context
data "azurerm_client_config" "current" {}

# Azure Container Registry Integration (optional)
resource "azurerm_role_assignment" "aks_acr_pull" {
  count              = 0  # Set to 1 if using ACR
  scope              = "/subscriptions/var.subscription_id/resourceGroups/var.resource_group_name/providers/Microsoft.ContainerRegistry/registries/your-acr-name"
  role_definition_name = "AcrPull"
  principal_id       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
