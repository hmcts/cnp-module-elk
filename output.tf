output "loadbalancer" {
  value = "${local.vNetLoadBalancerIp}"
}

output "kibana" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["kibana"]}"
}

output "jumpboxssh" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["jumpboxssh"]}"
}
