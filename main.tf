resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

//create the logstash resource group also so that it's there ready for logstash image creation
resource "azurerm_resource_group" "logstash-resourcegroup" {
  name     = "${var.product}-logstash-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

locals {
  artifactsBaseUrl = "https://raw.githubusercontent.com/hmcts/azure-marketplace/master/src"
  templateUrl = "${local.artifactsBaseUrl}/mainTemplate.json"
  elasticVnetName = "${var.product}-elastic-search-vnet-${var.env}"
  elasticSubnetName = "${var.product}-elastic-search-subnet-${var.env}"
  vNetLoadBalancerIp = "10.112.0.4"
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
    kibana            = "Yes"

    vmHostNamePrefix = "${var.product}-"

    adminUsername     = "elkadmin"
    adminPassword     = "password123!"
    securityAdminPassword = "password123!"
    securityKibanaPassword = "password123!"
    securityBootstrapPassword = ""
    securityLogstashPassword = "password123!"
    securityReadPassword = "password123!"

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