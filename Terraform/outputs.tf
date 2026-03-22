# Output para generar el inventario de Ansible automáticamente
output "ansible_inventory" {
  value = <<-EOT
[webservers]
${azurerm_public_ip.pip.ip_address} ansible_user=${var.admin_username} ansible_ssh_private_key_file=../ssh_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOT
}
