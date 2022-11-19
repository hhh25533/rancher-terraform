# Variables for Azure infrastructure module

variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription id under which resources will be provisioned"
}

variable "azure_client_id" {
  type        = string
  description = "Azure client id used to create resources"
}

variable "azure_client_secret" {
  type        = string
  description = "Client secret used to authenticate with Azure apis"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant id used to create resources"
}

variable "azure_location" {
  type        = string
  description = "Azure location used for all resources"
  default     = "East US"
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "rancher"
}

variable "instance_type" {
  type        = string
  description = "Instance type used for all linux virtual machines"
  default     = "Standard_DS2_v2"
}

variable "rancher_kubernetes_version" {
  type        = string
  description = "Kubernetes version to use for Rancher server cluster"
  default     = "v1.23.9+k3s1"
}

variable "cert_manager_version" {
  type        = string
  description = "Version of cert-manager to install alongside Rancher (format: 0.0.0)"
  default     = "1.7.1"
}

variable "rancher_version" {
  type        = string
  description = "Rancher server version (format: v0.0.0)"
  default     = "2.6.8"
}

# Required
variable "rancher_server_admin_password" {
  type        = string
  description = "Admin password to use for Rancher server bootstrap, min. 12 characters"
}

# var.node_pools is a map of any
variable "node_pools" {
  type        = number
  default     = 3
}

# Local variables used to reduce repetition
locals {
  node_username = "azureuser"
}
