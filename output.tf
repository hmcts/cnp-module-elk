output "loadbalancerManual" {
  value = "${local.vNetLoadBalancerIp}"
}

output "loadbalancer" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["loadbalancer"]}"
}

output "kibana" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["kibana"]}"
}

output "jumpboxssh" {
  value = "${azurerm_template_deployment.elastic-iaas.outputs["jumpboxssh"]}"
}

output "elastic_resource_group_name" {
  value = "${azurerm_resource_group.elastic-resourcegroup.name}}"
}

output "elasticsearch_admin_password" {
  value = "${local.securePassword}"
}

