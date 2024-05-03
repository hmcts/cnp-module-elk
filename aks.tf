
data "azurerm_virtual_network" "aks_core_vnet" {
  provider            = azurerm.aks-infra
  name                = "core-infra-vnet-${var.env}"
  resource_group_name = "core-infra-${var.env}"
}

data "azurerm_subnet" "aks-00" {
  provider             = azurerm.aks-infra
  name                 = "aks-00"
  virtual_network_name = data.azurerm_virtual_network.aks_core_vnet.name
  resource_group_name  = data.azurerm_virtual_network.aks_core_vnet.resource_group_name
}

data "azurerm_subnet" "aks-01" {
  provider             = azurerm.aks-infra
  name                 = "aks-01"
  virtual_network_name = data.azurerm_virtual_network.aks_core_vnet.name
  resource_group_name  = data.azurerm_virtual_network.aks_core_vnet.resource_group_name
}

locals {
  env = var.env == "sandbox" ? "sbox" : var.env
}

resource "azurerm_network_security_rule" "aks_rule" {
  name                                       = "AKS_To_ES"
  description                                = "Allow AKS to access the ElasticSearch cluster"
  priority                                   = 215
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9200"
  source_address_prefixes                    = [data.azurerm_subnet.aks-00.address_prefix, data.azurerm_subnet.aks-01.address_prefix]
  destination_application_security_group_ids = [data.azurerm_application_security_group.data_asg.id]
  resource_group_name                        = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name                = data.azurerm_network_security_group.cluster_nsg.name
  depends_on                                 = ["azurerm_template_deployment.elastic-iaas"]
}
