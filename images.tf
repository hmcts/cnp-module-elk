data "azurerm_image" "logstash" {
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  name_regex          = "^logstash-image-\\d{4,4}-\\d{2,2}-\\d{2,2}T\\d{6,6}"
  sort_descending     = true
}