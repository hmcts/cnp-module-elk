resource "azurerm_template_deployment" "alert_cluster_health" {
  name                = "alert_cluster_health"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    EmailRecipients = "ccd-devops@hmcts.net"
    DisplayNameOfSearch = "Cluster health is not green"
    UniqueNameOfSearch = "Cluster-unhealthy"
    Description = "Checks that status_s for the healthcheck is != green"
    SearchQuery = "es_health_CL | where status_s != \"green\""
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
