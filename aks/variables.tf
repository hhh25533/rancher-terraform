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
  default     = "Standard_DS2_v3"
}

# var.node_pools is a map of any
variable "node_counts" {
  type    = number
  default = 3
}

variable "ssh_public_key" {
  default = "./id_rsa.pub"
}

# Local variables used to reduce repetition
locals {
  node_username = "azureuser"
}


