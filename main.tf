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
  template_body       = "${data.template_file.elktemplate.rendered}"
  name                = "${var.product}-${var.env}"
  resource_group_name = "${azurerm_resource_group.elk-resourcegroup.name}"
  deployment_mode     = "Incremental"

  parameters = {
    cachename = "${var.product}-${var.env}"
    location  = "${azurerm_resource_group.elk-resourcegroup.location}"
    subnetid  = "${var.subnetid}"
    env       = "${var.env}"
  }
}
