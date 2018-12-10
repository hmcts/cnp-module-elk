module "elastic_devops_action_group" {
  source = "git@github.com:hmcts/cnp-module-action-group"
  location = "global"
  env = "${var.env}"
  resourcegroup_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name = "ElasticSearch_DevOps_Prod"
  short_name = "es-do-prod"
  email_receiver_name = "Elasticsearch Alerts (DevOps - Prod)"
  email_receiver_address = "ccd-elasticsearch-health-red@hmcts-devops.pagerduty.com"
}

module "elastic_ccd_action_group" {
  source = "git@github.com:hmcts/cnp-module-action-group"
  location = "global"
  env = "${var.env}"
  resourcegroup_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name = "ElasticSearch_CCD_DevOps"
  short_name = "es-ccd-ops"
  email_receiver_name = "Elasticsearch Alerts (CCD)"
  email_receiver_address = "CCD_DevOps@hmcts.net"
}

resource "azurerm_template_deployment" "alert_cluster_health_not_green" {
  name                = "alert_cluster_health_not_green"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName = "${module.elastic_ccd_action_group.action_group_name}"
    DisplayNameOfSearch = "Cluster health is not green"
    UniqueNameOfSearch = "Cluster-unhealthy"
    Description = "Checks that status_s for the healthcheck is != green"
    SearchQuery = "es_health_CL | where status_s != \"green\""
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
  name                = "alert_cluster_health_red"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName = "${module.elastic_devops_action_group.action_group_name}"
    DisplayNameOfSearch = "Cluster health is RED"
    UniqueNameOfSearch = "Cluster-down"
    Description = "Checks that status_s for the healthcheck is == red"
    SearchQuery = "es_health_CL | where status_s == \"red\""
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
