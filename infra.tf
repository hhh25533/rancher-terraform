# Azure Infrastructure Resources
// ensure computer_name meets 15 character limit
// uses assumption that resources only use 4 characters for a suffix
locals {
  computer_name_prefix = "tfvmex"
}

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "local_sensitive_file" "ssh_private_key_pem" {
  filename        = "${path.module}/id_rsa"
  content         = tls_private_key.global_key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Resource group containing all resources
resource "azurerm_resource_group" "rancher" {
  name     = "${var.prefix}"
  location = var.azure_location

  tags = {
    Creator = "terraform"
  }
}

# Public IP of Rancher server
resource "azurerm_public_ip" "management-server-pip" {
  name                = "management-server-pip"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name
  allocation_method   = "Dynamic"

  tags = {
    Creator = "terraform"
  }
}

# Azure virtual network space for quickstart resources
resource "azurerm_virtual_network" "rancher" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name

  tags = {
    Creator = "terraform"
  }
}

# Azure internal subnet for quickstart resources
resource "azurerm_subnet" "rancher-internal" {
  name                 = "rancher-internal"
  resource_group_name  = azurerm_resource_group.rancher.name
  virtual_network_name = azurerm_virtual_network.rancher.name
  address_prefixes     = ["10.0.0.0/24"]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "rancher-SecurityGroup" {
  name                = "rancher-SecurityGroup"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name

  security_rule {
    name                       = "SSH"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Azure network interface for quickstart resources
resource "azurerm_network_interface" "management-server-interface" {
  name                = "management-server-network-interface"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name

  ip_configuration {
    name                          = "management_server_ip_config"
    subnet_id                     = azurerm_subnet.rancher-internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.management-server-pip.id
  }

  tags = {
    Creator = "terraform"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "management-server-association" {
  network_interface_id      = azurerm_network_interface.management-server-interface.id
  network_security_group_id = azurerm_network_security_group.rancher-SecurityGroup.id
}

# Azure linux virtual machine for creating a single node RKE cluster and installing the Rancher Server
resource "azurerm_linux_virtual_machine" "management-server" {
  name                  = "${var.prefix}-management-server"
  computer_name         = "${local.computer_name_prefix}-management-server" // ensure computer_name meets 15 character limit
  location              = azurerm_resource_group.rancher.location
  resource_group_name   = azurerm_resource_group.rancher.name
  network_interface_ids = [azurerm_network_interface.management-server-interface.id]
  size                  = var.instance_type
  admin_username        = local.node_username

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = local.node_username
    public_key = tls_private_key.global_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  tags = {
    Creator = "terraform"
  }
}


# Azure network interface for quickstart resources
resource "azurerm_network_interface" "network_interface" {
  count               = var.node_pools

  name                = "vm${count.index}-network-interface"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name

  ip_configuration {
    name                          = "vm${count.index}_ip_config"
    subnet_id                     = azurerm_subnet.rancher-internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Creator = "terraform"
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "security_association" {
  count               = var.node_pools

  network_interface_id      = azurerm_network_interface.network_interface[count.index].id
  network_security_group_id = azurerm_network_security_group.rancher-SecurityGroup.id
}


# Azure linux virtual machine for creating a single node RKE cluster and installing the Rancher Server
resource "azurerm_linux_virtual_machine" "vm" {
  count               = var.node_pools


  name                  = "${var.prefix}-vm${count.index}"
  computer_name         = "${local.computer_name_prefix}-vm${count.index}" // ensure computer_name meets 15 character limit
  location              = azurerm_resource_group.rancher.location
  resource_group_name   = azurerm_resource_group.rancher.name
  network_interface_ids = [azurerm_network_interface.network_interface[count.index].id]
  size                  = var.instance_type
  admin_username        = local.node_username

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = local.node_username
    public_key = tls_private_key.global_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  tags = {
    Creator = "terraform"
  }
}


resource "azurerm_public_ip" "lb_pip" {
  name                = "lb_pip"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Creator = "terraform"
  }
}

resource "azurerm_lb" "load_balancer" {
  name                = "load_balancer"
  location            = azurerm_resource_group.rancher.location
  resource_group_name = azurerm_resource_group.rancher.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "backend_pool"

}

resource "azurerm_network_interface_backend_address_pool_association" "backend_pool_association" {
  count                   = var.node_pools

  network_interface_id    = azurerm_network_interface.network_interface[count.index].id
  ip_configuration_name   = "vm${count.index}_ip_config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_lb_outbound_rule" "outbound_rule" {
  name                    = "OutboundRule"
  loadbalancer_id         = azurerm_lb.load_balancer.id
  protocol                = "Tcp"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}

resource "azurerm_lb_nat_rule" "lb_nat_rule_http" {
  resource_group_name            = azurerm_resource_group.rancher.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port_start            = 80
  frontend_port_end              = 83
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_nat_rule" "lb_nat_rule_https" {
  resource_group_name            = azurerm_resource_group.rancher.name
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "https"
  protocol                       = "Tcp"
  frontend_port_start            = 443
  frontend_port_end              = 445
  backend_port                   = 443
  backend_address_pool_id        = azurerm_lb_backend_address_pool.backend_pool.id
  frontend_ip_configuration_name = "PublicIPAddress"
}