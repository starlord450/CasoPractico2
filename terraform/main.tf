# Despliegue de acr
resource "azurerm_resource_group" "repositorio_rg" {
  name     = "grupo_recursos"
  location = "Sweden Central"
}

resource "azurerm_container_registry" "micontainer" {
  name                = "miazurecontainerregistry"
  resource_group_name = azurerm_resource_group.repositorio_rg.name
  location            = azurerm_resource_group.repositorio_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

/*
# subir imagen al acr
resource "null_resource" "upload_image_to_acr" {
  depends_on = [azurerm_container_registry.micontainer]

  provisioner "local-exec" {
    command = "az acr build --registry ${azurerm_container_registry.micontainer.name} --image nombreimagen:tag ."
  }
}
*/ 


# despliegue de la VM Linux
# creacion de red virtual
resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.repositorio_rg.location
  resource_group_name = azurerm_resource_group.repositorio_rg.name
}

# Crear la subred
resource "azurerm_subnet" "my_terraform_subnet" { 
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.repositorio_rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Crear las IPs públicas
resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.repositorio_rg.location
  resource_group_name = azurerm_resource_group.repositorio_rg.name
  allocation_method   = "Static"
}

# Crear el grupo de seguridad de red y la regla
resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.repositorio_rg.location
  resource_group_name = azurerm_resource_group.repositorio_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  #trafico entrante en el puerto 80
  security_rule {
    name                       = "HTTP"
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

# Crear la interfaz de red
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.repositorio_rg.location
  resource_group_name = azurerm_resource_group.repositorio_rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Conectar el grupo de seguridad a la interfaz de red
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generar una nueva clave SSH
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


# Crear la máquina virtual
resource "azurerm_linux_virtual_machine" "vmubuntu" {
  name                  = "myvmubuntu"
  location              = azurerm_resource_group.repositorio_rg.location
  resource_group_name   = azurerm_resource_group.repositorio_rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"
  admin_username        = "adminuser"

  os_disk {
    name                 = "vmubuntuOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.example.public_key_openssh
  }

}

# Despliegue cluster de AKS
resource "azurerm_kubernetes_cluster" "cluster_aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.repositorio_rg.location
  resource_group_name = azurerm_resource_group.repositorio_rg.name
  dns_prefix          = "dns-cluster"
  kubernetes_version  = "1.27.9"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "despliegue-cluster-aks"
  }

}