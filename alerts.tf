module "elastic_devops_action_group" {
  source = "git@github.com:hmcts/cnp-module-action-group"
  location = "global"
  env = "${var.env}"
  resourcegroup_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name = "ElasticSearch_DevOps_${var.env}"
  short_name = "es-do-prod"
  email_receiver_name = "Elasticsearch Alerts (DevOps - ${var.env})"
  email_receiver_address = "ccd-elasticsearch-health-red@hmcts-devops.pagerduty.com"
}

module "elastic_ccd_action_group" {
  source = "git@github.com:hmcts/cnp-module-action-group"
  location = "global"
  env = "${var.env}"
  resourcegroup_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name = "ElasticSearch_CCD_DevOps_${var.env}"
  short_name = "es-ccd-ops"
  email_receiver_name = "Elasticsearch Alerts (CCD) - ${var.env}"
  email_receiver_address = "CCD_DevOps@hmcts.net"
}

resource "azurerm_template_deployment" "alert_cluster_health_not_green" {
  count               = "${var.subscription != "sandbox" ? 1 : 0}"
  name                = "alert_cluster_health_not_green_${var.env}"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName = "${module.elastic_ccd_action_group.action_group_name}"
    DisplayNameOfSearch = "Cluster health is not green on ${var.env}"
    UniqueNameOfSearch = "Cluster-unhealthy-${var.env}"
    Description = "Checks that status_s for the healthcheck is != green on ${var.env}"
    SearchQuery = "es_health_CL | where (status_s != \"green\" and cluster_s == \"${azurerm_resource_group.elastic-resourcegroup.name}\") or error_type_s != \"\""
    Severity = "warning"
    TimeWindow = "10"
    AlertFrequency = "5"
    AggregateValueOperator = "gt"
    AggregateValue = "0"
    TriggerAlertCondition = "Total"
    TriggerAlertOperator = "gt"
    TriggerAlertValue = "0"
  }
}

resource "azurerm_template_deployment" "alert_cluster_health_red" {
  count               = "${var.env == "prod" ? 1 : 0}"
  name                = "alert_cluster_health_red_${var.env}"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName = "${module.elastic_devops_action_group.action_group_name}"
    DisplayNameOfSearch = "Cluster health is RED ${var.env}"
    UniqueNameOfSearch = "Cluster-down-${var.env}"
    Description = "Checks that status_s for the healthcheck is == red on ${var.env}"
    SearchQuery = "es_health_CL | where (status_s == \"red\" and cluster_s == \"${azurerm_resource_group.elastic-resourcegroup.name}\") or error_type_s != \"\""
    Severity = "critical"
    TimeWindow = "10"
    AlertFrequency = "5"
    AggregateValueOperator = "gt"
    AggregateValue = "0"
    TriggerAlertCondition = "Total"
    TriggerAlertOperator = "gt"
    TriggerAlertValue = "0"
  }
}

resource "azurerm_template_deployment" "alert_dead_letter_queue" {
  count               = "${var.subscription != "sandbox" ? 1 : 0}"
  name                = "alert_dead_letter_queue"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName = "${module.elastic_ccd_action_group.action_group_name}"
    DisplayNameOfSearch = "ElasticSearch deadletter queue is not empty"
    UniqueNameOfSearch = "Cluster-deadletters_present"
    Description = "Checks that status_s for the healthcheck is != green"
    SearchQuery = "es_indices_CL | where index_s == \".logstash_dead_letter\" and docs_count_s != \"0\""
    Severity = "warning"
    TimeWindow = "10"
    AlertFrequency = "5"
    AggregateValueOperator = "gt"
    AggregateValue = "0"
    TriggerAlertCondition = "Total"
    TriggerAlertOperator = "gt"
    TriggerAlertValue = "0"
  }
}
