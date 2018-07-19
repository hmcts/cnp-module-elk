resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

data "template_file" "elktemplate" {
  template = "${file("${path.module}/templates/mainTemplate.json")}"
}

resource "azurerm_template_deployment" "elastic-iaas" {
  name                = "${var.product}-${var.env}"
  template_body       = "${data.template_file.elktemplate.rendered}"
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  deployment_mode     = "Incremental"

  parameters = {
    esClusterName     = "${var.product}-elastic-search-${var.env}"
    location          = "${azurerm_resource_group.elastic-resourcegroup.location}"
    esVersion         = "6.3.0"
    xpackPlugins      = "No"
    kibana            = "Yes"
    adminUsername     = "elkadmin"
    adminPassword     = "password"
    securityAdminPassword = "password"
    securityKibanaPassword = "password"
    securityBootstrapPassword = ""
    securityLogstashPassword = "password"
    securityReadPassword = "password"
    vNetNewOrExisting = "existing"
    vNetName          = "${var.vNetName}"
    vNetExistingResourceGroup = "${var.vNetExistingResourceGroup}"
    vNetClusterSubnetName = "${var.vNetClusterSubnetName}"
    vNetLoadBalancerIp = "${var.vNetLoadBalancerIp}"
  }
}
