# Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-podman-nginx"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Trusted Launch - Seguridad mejorada (según política TrustedLaunchSupported)
  secure_boot_enabled = true
  vtpm_enabled        = true

  # Deshabilitar discos no administrados (según política vmDiskType: Unmanaged disallowed)
  # Los discos managed son el default, no se requiere configuración adicional
}
