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

resource "azurerm_template_deployment" "alert_cluster_health" {
  name                = "alert_cluster_health"
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
