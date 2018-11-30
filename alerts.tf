module "elastic_action_group" {
  source = "git@github.com:hmcts/cnp-module-action-group"
  location = "global"
  env = "${var.env}"
  resourcegroup_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name = "elasticsearch_devops"
  short_name = "es-devops"
  email_receiver_name = "Elasticsearch Alerts"
  email_receiver_address = "Dwayne.Bailey@hmcts.net"
}

resource "azurerm_template_deployment" "alert_cluster_health" {
  name                = "alert_cluster_health"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName = "${module.elastic_action_group.action_group_name}"
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