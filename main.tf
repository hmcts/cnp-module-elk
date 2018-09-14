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
  artifactsBaseUrl = "https://raw.githubusercontent.com/elastic/azure-marketplace/6.3.0/src"
  templateUrl = "${local.artifactsBaseUrl}/mainTemplate.json"
  elasticVnetName = "${var.product}-elastic-search-vnet"
  elasticSubnetName = "${var.product}-elastic-search-subnet"
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

  parameters_body = <<DEPLOY
  {
    "parameters": {
    "vmDataNodeCount": {
      "type": "int",
      "value": 2
    }

    "artifactsBaseUrl  = "${local.artifactsBaseUrl}"
    "esClusterName     = "${var.product}-elastic-search-${var.env}"
    "location          = "${azurerm_resource_group.elastic-resourcegroup.location}"

    "esVersion         = "6.3.0"
    "xpackPlugins      = "No"
    "kibana            = "Yes"

    "vmHostNamePrefix = "${var.product}-"

    "adminUsername     = "elkadmin"
    "adminPassword     = "password123!"
    "securityAdminPassword = "password123!"
    "securityKibanaPassword = "password123!"
    "securityBootstrapPassword = ""
    "securityLogstashPassword = "password123!"
    "securityReadPassword = "password123!"

    "vNetNewOrExisting = "new"
    "vNetName          = "${local.elasticVnetName}"
    "vNetNewAddressPrefix = "10.112.0.0/16"
    "vNetLoadBalancerIp = "${local.vNetLoadBalancerIp}"
    "vNetClusterSubnetName = "${local.elasticSubnetName}"
    "vNetNewClusterSubnetAddressPrefix = "10.112.0.0/25"

    "vmSizeKibana = "Standard_A2"
    "vmSizeDataNodes = "Standard_A2"
    "vmSizeClientNodes = "Standard_A2"
    "vmSizeMasterNodes = "Standard_A2"

    "dataNodesAreMasterEligible = "${var.dataNodesAreMasterEligible}"

    "esAdditionalYaml = "action.auto_create_index: .security*,.monitoring*,.watches,.triggered_watches,.watcher-history*,.ml*\n"
  }
  }
  DEPLOY
}