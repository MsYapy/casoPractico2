# Configuración específica del entorno
resource_group_name     = "rg-podman-nginx"
location                = "westus2"
admin_username          = "azureuser"
vm_size                 = "Standard_D2s_v3"
vnet_address_space      = ["10.0.0.0/16"]
subnet_address_prefixes = ["10.0.1.0/24"]

# Azure Subscription (Azure for Students - UNIR)
subscription_id = "***"
