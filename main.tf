terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.0"
    }
  }
    cloud {
    organization = "Protek" // Replace with your Terraform Cloud organization name

    workspaces {
      name = "CR460H2025" // Replace with your Terraform Cloud workspace name
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "terraform-rg"
  location = "East US" // Choose an Azure region near you
}

resource "azurerm_virtual_network" "vnet" {
  name                = "terraform-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "terraform-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "terraform-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s" // Choose a VM size (this is a small, inexpensive one)
  admin_username      = "adminuser"
  admin_password      = "Password1234!"  // Use a strong password!  Better yet, use SSH keys (see note below)
  disable_password_authentication = false // Set to true and use os_profile_linux_config for SSH keys
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
# for using ssh key
/*
  os_profile_linux_config {
    disable_password_authentication = true
     ssh_keys {
      path = "/home/adminuser/.ssh/authorized_keys"
      key_data = file("~/.ssh/id_rsa.pub")
    }
  }
*/
resource "azurerm_public_ip" "public_ip" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "vm-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" // Ideally, restrict this to your IP address
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_container_group" "container_group" {
  name                = "terraform-container"  // Keep this name, or choose your own
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "cr460-azure" // ***IMPORTANT: CHANGE THIS***
  os_type             = "Linux"

  container {
    name   = "cr460-container"
    image  = "nginx:latest" // Or your preferred Docker image
    cpu    = "0.5"  // Adjust as needed
    memory = "1.5"  // Adjust as needed

    ports {
      port     = 80
      protocol = "TCP"
    }
    # Optional: Environment variables for the container
    environment_variables = {
      "MY_VARIABLE" = "my_value"  // Example - add your own
    }
  }
    restart_policy = "OnFailure"
}

output "container_group_ip" {
  value = azurerm_container_group.container_group.ip_address
}

output "container_group_fqdn" {
    value = azurerm_container_group.container_group.fqdn
}
