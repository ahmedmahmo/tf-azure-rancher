resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-${var.name}-rg"
  location = "West Europe"
  tags = {
    Created_by: "Terraform",
    Created_from: "Ahmed",
    Target: "Rancher on Ubuntu Kubernetes Cluster"
  }
}










