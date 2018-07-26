resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

locals {
  artifactsBaseUrl = "https://raw.githubusercontent.com/elastic/azure-marketplace/6.3.0/src"
  templateUrl = "${local.artifactsBaseUrl}/mainTemplate.json"
}

data "http" "template" {
url = "${local.templateUrl}"
}

resource "azurerm_template_deployment" "elastic-iaas" {
  name                = "${var.product}-${var.env}"
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

    adminUsername     = "elkadmin"
    adminPassword     = "password123!"
    securityAdminPassword = "password123!"
    securityKibanaPassword = "password123!"
    securityBootstrapPassword = ""
    securityLogstashPassword = "password123!"
    securityReadPassword = "password123!"

    vNetNewOrExisting = "new"
    vNetName          = "elastic-search-sandbox-vnet"
    vNetNewAddressPrefix = "40.0.0.0/24"
    vNetLoadBalancerIp = "40.0.0.4"
    vNetNewClusterSubnetAddressPrefix = "40.0.0.0/25"

    vmSizeKibana = "Standard_A2"
    vmSizeDataNodes = "Standard_A2"
    vmSizeClientNodes = "Standard_A2"
    vmSizeMasterNodes = "Standard_A2"

    vmDataNodeCount = 2
  }
}
