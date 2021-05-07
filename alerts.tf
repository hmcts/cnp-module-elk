module "elastic_action_group" {
  source                 = "git@github.com:hmcts/cnp-module-action-group"
  location               = "global"
  env                    = "${var.env}"
  resourcegroup_name     = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name      = "${var.product}-ElasticSearch_${var.env}"
  short_name             = "${var.product}-es-do-prod"
  email_receiver_name    = "Elasticsearch Alerts - ${var.env}"
  email_receiver_address = "${var.alerts_email}"
}

module "elastic_action_group" {
  source                 = "git@github.com:hmcts/cnp-module-action-group"
  location               = "global"
  env                    = "${var.env}"
  resourcegroup_name     = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  action_group_name      = "${var.product}_ElasticSearch_${var.env}"
  short_name             = "es-${var.product}-ops"
  email_receiver_name    = "Elasticsearch Alerts (${var.product}) - ${var.env}"
  email_receiver_address = "${var.alerts_email}"
}

resource "azurerm_template_deployment" "alert_cluster_health_not_green" {
  count               = "${var.subscription != "sandbox" ? 1 : 0}"
  name                = "${var.product}_alert_cluster_health_not_green_${var.env}"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName          = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName        = "${module.elastic_action_group.action_group_name}"
    DisplayNameOfSearch    = "${var.product} Cluster health is not green on ${var.env}"
    UniqueNameOfSearch     = "Cluster-unhealthy-${var.env}"
    Description            = "Checks that status_s for the healthcheck is != green on ${var.env}"
    SearchQuery            = "es_health_CL | where (status_s != \"green\" and cluster_s == \"${azurerm_resource_group.elastic-resourcegroup.name}\") or error_type_s != \"\""
    Severity               = "warning"
    TimeWindow             = "10"
    AlertFrequency         = "5"
    AggregateValueOperator = "gt"
    AggregateValue         = "0"
    TriggerAlertCondition  = "Total"
    TriggerAlertOperator   = "gt"
    TriggerAlertValue      = "0"
  }
}

resource "azurerm_template_deployment" "alert_cluster_health_red" {
  count               = "${var.env == "prod" ? 1 : 0}"
  name                = "${var.product}_alert_cluster_health_red_${var.env}"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName          = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName        = "${module.elastic_action_group.action_group_name}"
    DisplayNameOfSearch    = "${var.product} Cluster health is RED ${var.env}"
    UniqueNameOfSearch     = "${var.product}-Cluster-down-${var.env}"
    Description            = "Checks that status_s for the healthcheck is == red on ${var.env}"
    SearchQuery            = "es_health_CL | where (status_s == \"red\" and cluster_s == \"${azurerm_resource_group.elastic-resourcegroup.name}\") or error_type_s != \"\""
    Severity               = "critical"
    TimeWindow             = "10"
    AlertFrequency         = "5"
    AggregateValueOperator = "gt"
    AggregateValue         = "0"
    TriggerAlertCondition  = "Total"
    TriggerAlertOperator   = "gt"
    TriggerAlertValue      = "0"
  }
}

resource "azurerm_template_deployment" "alert_dead_letter_queue" {
  count               = "${var.subscription != "sandbox" ? 1 : 0}"
  name                = "${var.product}alert_dead_letter_queue"
  template_body       = "${file("${path.module}/templates/alert.json")}"
  resource_group_name = "${data.azurerm_log_analytics_workspace.log_analytics.resource_group_name}"
  deployment_mode     = "Incremental"

  parameters = {
    workspaceName          = "${data.azurerm_log_analytics_workspace.log_analytics.name}"
    ActionGroupName        = "${module.elastic_action_group.action_group_name}"
    DisplayNameOfSearch    = "${var.product} ElasticSearch deadletter queue is not empty in ${var.env}"
    UniqueNameOfSearch     = "${var.product}_Cluster-deadletters_${var.env}"
    Description            = "Check that deadletter queue is empty in ${var.env}"
    SearchQuery            = "es_indices_CL | where index_s == \".logstash_dead_letter\" and docs_count_s != \"0\" and _ResourceId contains \"${azurerm_resource_group.elastic-resourcegroup.name}\""
    Severity               = "warning"
    TimeWindow             = "10"
    AlertFrequency         = "5"
    AggregateValueOperator = "gt"
    AggregateValue         = "0"
    TriggerAlertCondition  = "Total"
    TriggerAlertOperator   = "gt"
    TriggerAlertValue      = "0"
    ThrottleDuration       = "${var.env == "prod" ? 30 : 24 * 60}"
  }
}
