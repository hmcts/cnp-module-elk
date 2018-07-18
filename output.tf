output "loadbalancer" {
  value = "${azurerm_template_deployment.elk-iaas.outputs["loadbalancer"]}"
}

output "kibana" {
  value = "${azurerm_template_deployment.elk-iaas.outputs["kibana"]}"
}

output "jumpboxssh" {
  value = "${azurerm_template_deployment.elk-iaas.outputs["jumpboxssh"]}"
}
