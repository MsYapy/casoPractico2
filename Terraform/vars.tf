variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-podman-nginx"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Tamaño de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "vnet_address_space" {
  description = "Espacio de direcciones de la VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Prefijos de la subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
  default     = ""
}
