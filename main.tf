resource "azurerm_resource_group" "elk-resourcegroup" {
  name     = "${var.product}-elk-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

data "template_file" "elktemplate" {
  template = "${file("${path.module}/templates/mainTemplate.json")}"
}

resource "azurerm_template_deployment" "elk-iaas" {
  name                = "${var.product}-${var.env}"
  template_body       = "${data.template_file.elktemplate.rendered}"
  resource_group_name = "${azurerm_resource_group.elk-resourcegroup.name}"
  deployment_mode     = "Incremental"

  parameters = {
    esClusterName     = "${var.product}-elk-${var.env}"
    location          = "${azurerm_resource_group.elk-resourcegroup.location}"
    xpackPlugins      = "No"
    kibana            = "Yes"
    adminUsername     = "admin"
    adminPassword     = "password"
    securityAdminPassword = "password"
    securityKibanaPassword = "password"
    securityBootstrapPassword = ""
    securityLogstashPassword = "password"
    securityReadPassword = "password"
    vNetNewOrExisting = "existing"
    vNetExistingResourceGroup = "core-infra-ccdelasticsearch"
    vNetName          = "core-infra-vnet-ccdelasticsearch"
    vNetClusterSubnetName = "core-infra-subnet-3-ccdelasticsearch"
  }
}
