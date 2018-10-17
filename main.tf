resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

resource "random_string" "password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  number  = true
}

locals {
  artifactsBaseUrl = "https://raw.githubusercontent.com/hmcts/azure-marketplace/master/src"
  templateUrl = "${local.artifactsBaseUrl}/mainTemplate.json"
  elasticVnetName = "${var.product}-elastic-search-vnet-${var.env}"
  vNetLoadBalancerIp = "cidrhost(${data.azurerm_subnet.elastic-subnet.address_prefix}, 254)"
  administratorLoginPassword = "${random_string.password.result}"
}

data "http" "template" {
  url = "${local.templateUrl}"
}

resource "azurerm_template_deployment" "elastic-iaas" {
  name                = "${azurerm_resource_group.elastic-resourcegroup.name}-template"
  template_body       = "${data.http.template.body}"
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  deployment_mode     = "Incremental"

  parameters = {
    # See https://github.com/elastic/azure-marketplace#parameters
    artifactsBaseUrl  = "${local.artifactsBaseUrl}"
    esClusterName     = "${var.product}-elastic-search-${var.env}"
    location          = "${azurerm_resource_group.elastic-resourcegroup.location}"

    esVersion         = "6.3.0"
    xpackPlugins      = "No"
    kibana            = "No"

    vmHostNamePrefix = "${var.product}-"

    adminUsername     = "elkadmin"
    adminPassword     = "${local.administratorLoginPassword}"
    securityAdminPassword = "${local.administratorLoginPassword}"
    securityKibanaPassword = "${local.administratorLoginPassword}"
    securityBootstrapPassword = ""
    securityLogstashPassword = "${local.administratorLoginPassword}"
    securityReadPassword = "${local.administratorLoginPassword}"

    vNetNewOrExisting = "existing"
    vNetName          = "${data.azurerm_virtual_network.core_infra_vnet.name}"
    vNetExistingResourceGroup = "${data.azurerm_virtual_network.core_infra_vnet.resource_group_name}"
    vNetLoadBalancerIp = "${local.vNetLoadBalancerIp}"
    vNetClusterSubnetName = "${data.azurerm_subnet.elastic-subnet.name}"

    vmSizeKibana = "Standard_A2"
    vmSizeDataNodes = "${var.vmSizeAllNodes}"
    vmSizeClientNodes = "${var.vmSizeAllNodes}"
    vmSizeMasterNodes = "${var.vmSizeAllNodes}"

    dataNodesAreMasterEligible = "${var.dataNodesAreMasterEligible}"

    vmDataNodeCount = "${var.vmDataNodeCount}"
    vmDataDiskCount = "${var.vmDataDiskCount}"
    vmClientNodeCount = "${var.vmClientNodeCount}"
    storageAccountType = "${var.storageAccountType}"

    esAdditionalYaml = "${var.esAdditionalYaml}"
  }
}

data "azurerm_virtual_network" "core_infra_vnet" {
  name                 = "core-infra-vnet-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
}

data "azurerm_subnet" "elastic-subnet" {
  name                 = "elasticsearch"
  virtual_network_name = "${data.azurerm_virtual_network.core_infra_vnet.name}"
  resource_group_name  = "${data.azurerm_virtual_network.core_infra_vnet.resource_group_name}"
}
