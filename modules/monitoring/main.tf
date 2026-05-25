resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.environment_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# Enable analytics for common data sources
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_log_analytics_solution" "key_vault_analytics" {
  solution_name         = "KeyVaultAnalytics"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/KeyVaultAnalytics"
  }
}

# Application Insights for APM
resource "azurerm_application_insights" "main" {
  name                = "${var.environment_prefix}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id
  tags                = var.tags

  daily_data_cap_in_gb = 100
}

# Action Groups for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.environment_prefix}-ag"
  resource_group_name = var.resource_group_name
  short_name          = substr(var.environment_prefix, 0, 12)
  tags                = var.tags
}

# Alert Rule: High CPU Usage
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "${var.environment_prefix}-high-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = []  # Add resource IDs to monitor
  description         = "Alert when CPU usage is high"
  severity            = 2
  enabled             = true

  criteria {
    metric_name      = "Percentage CPU"
    metric_namespace = "Microsoft.Compute/virtualMachines"
    operator         = "GreaterThan"
    threshold        = 85
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Alert Rule: High Memory Usage
resource "azurerm_monitor_metric_alert" "high_memory" {
  name                = "${var.environment_prefix}-high-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = []  # Add resource IDs to monitor
  description         = "Alert when memory usage is high"
  severity            = 2
  enabled             = true

  criteria {
    metric_name      = "Available Memory Bytes"
    metric_namespace = "Microsoft.Compute/virtualMachines"
    operator         = "LessThan"
    threshold        = 1073741824  # 1GB in bytes
    aggregation      = "Average"
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

# Data Collection Rule for VM Monitoring
resource "azurerm_monitor_data_collection_rule" "vm_monitoring" {
  name                = "${var.environment_prefix}-dcr"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  data_flow {
    destinations = [azurerm_log_analytics_workspace.main.name]
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
  }

  data_sources {
    syslog {
      facility_names = ["auth", "authpriv"]
      log_levels     = ["debug", "info", "notice", "warning", "err", "crit", "alert", "emerg"]
      name           = "syslog"
    }

    performance_counter {
      counter_specifiers            = ["\\Processor(_Total)\\% Processor Time", "\\Memory\\% Committed Bytes In Use"]
      sampling_frequency_in_seconds = 60
      streams                       = ["Microsoft-Perf"]
      name                          = "perfcounter"
    }
  }

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = azurerm_log_analytics_workspace.main.name
    }
  }
}

# Dashboard for visualization
resource "azurerm_portal_dashboard" "main" {
  count               = 0  # Set to 1 to create dashboard
  name                = "${var.environment_prefix}-dashboard"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x = 0
              y = 0
              colSpan = 4
              rowSpan = 4
            }
            metadata = {
              inputs = []
              type   = "Extension/HubsExtension/PartType/MarkdownPart"
              settings = {
                content = {
                  settings = {
                    content = "# Azure Infrastructure Dashboard\n\n### Key Metrics\n- AKS Cluster Health\n- Database Performance\n- Application Insights"
                  }
                }
              }
            }
          }
        }
      }
    }
  })
}
