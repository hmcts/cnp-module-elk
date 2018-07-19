output "loadbalancer" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["loadbalancer"]}"
}

output "kibana" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["kibana"]}"
}

output "jumpboxssh" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["jumpboxssh"]}"
}
