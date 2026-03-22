# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "acrcp2${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "random_string" "acr_suffix" {
  length  = 8
  special = false
  upper   = false
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  value     = azurerm_container_registry.acr.admin_password
  sensitive = true
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}
