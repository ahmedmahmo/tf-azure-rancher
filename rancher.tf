data "template_file" "rancher_server_template" {
  template = file("scripts/rancher.sh")
}

data "template_file" "master" {
  template = file("scripts/master.sh")
}

data "template_file" "worker" {
  template = file("scripts/worker.sh")
}

data "template_file" "etcd" {
  template = file("scripts/etcd.sh")
}

resource "tls_private_key" "private_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "null_resource" "key" {
  provisioner "local-exec" {
    command = "echo '${tls_private_key.private_ssh_key.private_key_pem}' > ./key.pem"
  }
}

resource "azurerm_linux_virtual_machine" "rancher_server" {
  depends_on=[azurerm_network_interface.master, azurerm_network_interface.worker]

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  name                  = "${var.prefix}-rancher-server"
  network_interface_ids = [azurerm_network_interface.rancher_server.id]
  size                  = local.vm_rancher_size

  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.ubuntu_1804_sku
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-rancher-server-osDisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name  = "rancherserver"
  admin_username = "norcom"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "norcom"
    public_key = tls_private_key.private_ssh_key.public_key_openssh
  }

  custom_data    = base64encode(data.template_file.rancher_server_template.rendered)
}

resource "azurerm_linux_virtual_machine" "masters" {
  depends_on=[azurerm_network_interface.master, azurerm_network_interface.worker]

  count = local.master_count

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  name                  = "${var.prefix}-master-${format("%02d", count.index)}"
  network_interface_ids = [element(azurerm_network_interface.master.*.id, count.index)]
  size                  = local.vm_master_size

  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.ubuntu_1804_sku
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-master-osDisk-${format("%02d", count.index)}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name  = "master${format("%02d", count.index)}"
  admin_username = "norcom"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "norcom"
    public_key = tls_private_key.private_ssh_key.public_key_openssh
  }

  custom_data    = base64encode(data.template_file.master.rendered)
}


resource "azurerm_linux_virtual_machine" "workers" {
  depends_on=[azurerm_network_interface.master, azurerm_network_interface.worker]

  count = local.worker_count

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  name                  = "${var.prefix}-worker-${format("%02d", count.index)}"
  network_interface_ids = [element(azurerm_network_interface.worker.*.id, count.index)]
  size                  = local.vm_worker_size

  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.ubuntu_1804_sku
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-worker-osDisk-${format("%02d", count.index)}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name  = "worker${format("%02d", count.index)}"
  admin_username = "norcom"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "norcom"
    public_key = tls_private_key.private_ssh_key.public_key_openssh
  }

  custom_data    = base64encode(data.template_file.worker.rendered)
}

resource "azurerm_linux_virtual_machine" "etcd" {
  depends_on=[azurerm_network_interface.master, azurerm_network_interface.worker]

  count = local.etcd_count

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  name                  = "${var.prefix}-etcd-${format("%02d", count.index)}"
  network_interface_ids = [element(azurerm_network_interface.etcd.*.id, count.index)]
  size                  = local.vm_etcd_size

  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.ubuntu_1804_sku
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-etcd-osDisk-${format("%02d", count.index)}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  computer_name  = "etcd${format("%02d", count.index)}"
  admin_username = "norcom"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "norcom"
    public_key = tls_private_key.private_ssh_key.public_key_openssh
  }

  custom_data    = base64encode(data.template_file.etcd.rendered)
}

########
# DISK #
#######
resource "azurerm_managed_disk" "masters" {
  count = local.master_count
  name                 = "${var.prefix}-dataDisk-master-${format("%02d", count.index)}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
}

resource "azurerm_managed_disk" "workers" {
  count = local.worker_count
  name                 = "${var.prefix}-dataDisk-worker-${format("%02d", count.index)}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 256
}


resource "azurerm_virtual_machine_data_disk_attachment" "masters" {
  count = local.master_count
  managed_disk_id    = element(azurerm_managed_disk.masters.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.masters.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "workers" {
  count = local.worker_count
  managed_disk_id    = element(azurerm_managed_disk.workers.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.workers.*.id, count.index)
  lun                = "10"
  caching            = "ReadWrite"
}


output "tls_private_key" {
  value     = tls_private_key.private_ssh_key.private_key_pem
  sensitive = true
}

output "master_ips" {
  value = azurerm_linux_virtual_machine.masters.*.public_ip_address
}

output "worker_ips" {
  value = azurerm_linux_virtual_machine.workers.*.private_ip_address
}


output "rancher_server" {
  value = azurerm_linux_virtual_machine.rancher_server.public_ip_address
}