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
  elasticSubnetName = "${var.product}-elastic-search-subnet-${var.env}"
  vNetLoadBalancerIp = "10.112.0.4"
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

    vNetNewOrExisting = "new"
    vNetName          = "${local.elasticVnetName}"
    vNetNewAddressPrefix = "10.112.0.0/16"
    vNetLoadBalancerIp = "${local.vNetLoadBalancerIp}"
    vNetClusterSubnetName = "${local.elasticSubnetName}"
    vNetNewClusterSubnetAddressPrefix = "10.112.0.0/25"

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

data "azurerm_virtual_network" "elastic_infra_vnet" {
  name                 = "${local.elasticVnetName}"
  resource_group_name  = "${azurerm_resource_group.elastic-resourcegroup.name}"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_virtual_network_peering" "elasticToCoreInfra" {
  name                      = "elasticToCoreInfra"
  resource_group_name       = "${azurerm_resource_group.elastic-resourcegroup.name}"
  virtual_network_name      = "${local.elasticVnetName}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.core_infra_vnet.id}"
  allow_virtual_network_access = "true"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_virtual_network_peering" "coreInfraToElastic" {
  name                      = "coreInfraToElastic"
  resource_group_name       = "core-infra-${var.env}"
  virtual_network_name      = "${data.azurerm_virtual_network.core_infra_vnet.name}"
  remote_virtual_network_id = "${data.azurerm_virtual_network.elastic_infra_vnet.id}"
  allow_virtual_network_access = "true"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}