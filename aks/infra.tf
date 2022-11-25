# Azure Infrastructure Resources
// ensure computer_name meets 15 character limit
// uses assumption that resources only use 4 characters for a suffix
locals {
  computer_name_prefix = "tfvmex"
}

# Resource group containing all resources
resource "azurerm_resource_group" "rancher" {
  name     = var.prefix
  location = var.azure_location

  tags = {
    Creator = "terraform"
  }
}

# Resource Kubernetes cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks1"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name
  dns_prefix          = "aks1-dns"

  default_node_pool {
    name       = "akspool"
    node_count = var.node_counts
    vm_size    = var.instance_type
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
  }

  tags = {
    Environment = "test",
    Creator     = "terraform"
  }
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks.kube_config_raw

  sensitive = true
}
