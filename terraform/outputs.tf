output "container_registry_name" {
  value = azurerm_container_registry.micontainer.name
}

output "resource_group_name" {
  value = azurerm_resource_group.repositorio_rg.name
}

output "private_key" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

