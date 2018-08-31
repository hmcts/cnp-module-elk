data "azurerm_image" "logstash" {
  resource_group_name = "ccd-elastic-search-sandbox"
  name_regex          = "^logstash-image-\\d{4,4}-\\d{2,2}-\\d{2,2}T\\d{6,6}"
  sort_descending     = true
}