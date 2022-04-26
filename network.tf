resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-${var.name}-Vnetwork"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}

resource "azurerm_subnet" "private" {
  name                 = "${var.prefix}-${var.name}-private-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "public" {
  name                 = "${var.prefix}-${var.name}-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]
}


resource "azurerm_public_ip" "main" {
  depends_on=[azurerm_resource_group.main]
  count = local.master_count
  name                = "${var.prefix}-${var.name}-public-ip-${format("%02d", count.index)}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Dynamic"
  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}

resource "azurerm_public_ip" "rancher_server" {
  depends_on=[azurerm_resource_group.main]
  name                = "${var.prefix}-${var.name}-public-ip-rancher"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  domain_name_label = "rancher-stihl"
  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}

resource "azurerm_network_interface" "etcd" {
  count = local.etcd_count
  name                = "${var.prefix}-${var.name}-etcd-interface-${format("%02d", count.index)}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-private-ip-config"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}

resource "azurerm_network_interface" "worker" {
  count = local.worker_count
  name                = "${var.prefix}-${var.name}-worker-interface-${format("%02d", count.index)}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-private-ip-config"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}

resource "azurerm_network_interface" "master" {
  count = local.master_count
  name                = "${var.prefix}-${var.name}-${format("%02d", count.index)}-master-interface"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-public-ip-config"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.main.*.id, count.index)
  }

  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}

resource "azurerm_network_interface" "rancher_server" {
  name                = "${var.prefix}-${var.name}-rancher-public-interface"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-public-ip-config"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.rancher_server.id
  }

  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}