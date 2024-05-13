
resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = var.location

  tags = merge(var.common_tags,
    tomap({ lastUpdated = timestamp()
  }))
}

resource "random_string" "password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  number  = true
}

locals {
  artifactsBaseUrl = "https://raw.githubusercontent.com/hmcts/azure-marketplace/7.11.1_hmcts/src/"
  templateUrl      = "${local.artifactsBaseUrl}mainTemplate.json"
  elasticVnetName  = "${var.product}-elastic-search-vnet-${var.env}"
  securePassword   = random_string.password.result

  mgmt_network_name = var.subscription == "prod" || var.subscription == "nonprod" || var.subscription == "qa" || var.subscription == "ethosldata" ? "cft-ptl-vnet" : "cft-ptlsbox-vnet"
  mgmt_rg_name      = var.subscription == "prod" || var.subscription == "nonprod" || var.subscription == "qa" || var.subscription == "ethosldata" ? "cft-ptl-network-rg" : "cft-ptlsbox-network-rg"
  bastion_ip        = var.subscription == "prod" || var.subscription == "ethosldata" ? data.azurerm_key_vault_secret.bastion_devops_ip.value : data.azurerm_key_vault_secret.bastion_dev_ip.value
}

data "http" "template" {
  url = local.templateUrl
}

resource "azurerm_template_deployment" "elastic-iaas" {
  name                = azurerm_resource_group.elastic-resourcegroup.name
  template_body       = data.http.template.body
  resource_group_name = azurerm_resource_group.elastic-resourcegroup.name
  deployment_mode     = "Incremental"

  parameters = {
    _artifactsLocation               = local.artifactsBaseUrl
    esClusterName                    = "${var.product}-elastic-search-${var.env}"
    location                         = azurerm_resource_group.elastic-resourcegroup.location
    esVersion                        = var.esVersion
    xpackPlugins                     = "No"
    kibana                           = var.enable_kibana ? "Yes" : "No"
    logstash                         = var.enable_logstash ? "Yes" : "No"
    vmHostNamePrefix                 = var.vmHostNamePrefix
    adminUsername                    = "elkadmin"
    authenticationType               = "sshPublicKey"
    sshPublicKey                     = var.ssh_elastic_search_public_key
    securityAdminPassword            = local.securePassword
    securityKibanaPassword           = local.securePassword
    securityBootstrapPassword        = ""
    securityLogstashPassword         = local.securePassword
    securityApmPassword              = local.securePassword
    securityRemoteMonitoringPassword = local.securePassword
    securityBeatsPassword            = local.securePassword
    vNetNewOrExisting                = "existing"
    vNetName                         = data.azurerm_virtual_network.core_infra_vnet.name
    vNetExistingResourceGroup        = data.azurerm_virtual_network.core_infra_vnet.resource_group_name
    vNetLoadBalancerIp               = var.vNetLoadBalancerIp
    vNetClusterSubnetName            = data.azurerm_subnet.elastic-subnet.name
    vmSizeKibana                     = "Standard_A2_v2"
    vmSizeDataNodes                  = var.vmSizeAllNodes
    vmSizeClientNodes                = var.vmSizeAllNodes
    vmSizeMasterNodes                = var.vmSizeAllNodes
    dataNodesAreMasterEligible       = var.dataNodesAreMasterEligible ? "Yes" : "No"
    vmDataNodeCount                  = var.vmDataNodeCount
    vmDataDiskCount                  = var.vmDataDiskCount
    vmClientNodeCount                = var.vmClientNodeCount
    storageAccountType               = var.storageAccountType
    vmDataNodeAcceleratedNetworking  = var.dataNodeAcceleratedNetworking
    esAdditionalYaml                 = var.esAdditionalYaml
    kibanaAdditionalYaml             = var.kibanaAdditionalYaml
    logAnalyticsId                   = var.logAnalyticsId
    logAnalyticsKey                  = var.logAnalyticsKey
  }
}

data "azurerm_virtual_network" "core_infra_vnet" {
  name                = "core-infra-vnet-${var.env}"
  resource_group_name = "core-infra-${var.env}"
}

data "azurerm_subnet" "elastic-subnet" {
  name                 = "elasticsearch"
  virtual_network_name = data.azurerm_virtual_network.core_infra_vnet.name
  resource_group_name  = data.azurerm_virtual_network.core_infra_vnet.resource_group_name
}

data "azurerm_subnet" "apps" {
  name                 = "core-infra-subnet-3-${var.env}"
  virtual_network_name = data.azurerm_virtual_network.core_infra_vnet.name
  resource_group_name  = data.azurerm_virtual_network.core_infra_vnet.resource_group_name
}

data "azurerm_subnet" "jenkins" {
  provider             = "azurerm.mgmt"
  name                 = "iaas"
  virtual_network_name = local.mgmt_network_name
  resource_group_name  = local.mgmt_rg_name
}

data "azurerm_network_security_group" "cluster_nsg" {
  name                = "${var.vmHostNamePrefix}cluster-nsg"
  resource_group_name = azurerm_resource_group.elastic-resourcegroup.name
  depends_on          = ["azurerm_template_deployment.elastic-iaas"]
}

data "azurerm_network_security_group" "kibana_nsg" {
  name                = "${var.vmHostNamePrefix}kibana-nsg"
  resource_group_name = azurerm_resource_group.elastic-resourcegroup.name
  depends_on          = ["azurerm_template_deployment.elastic-iaas"]

  count = var.enable_kibana ? 1 : 0
}

data "azurerm_application_security_group" "data_asg" {
  name                = "${var.vmHostNamePrefix}data-asg"
  resource_group_name = azurerm_resource_group.elastic-resourcegroup.name
  depends_on          = ["azurerm_template_deployment.elastic-iaas"]
}

data "azurerm_application_security_group" "kibana_asg" {
  name                = "${var.vmHostNamePrefix}kibana-asg"
  resource_group_name = azurerm_resource_group.elastic-resourcegroup.name
  depends_on          = ["azurerm_template_deployment.elastic-iaas"]

  count = var.enable_kibana ? 1 : 0
}

data "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "hmcts-${var.subscription}"
  resource_group_name = "oms-automation"
}

data "azurerm_key_vault" "infra_vault" {
  name                = "infra-vault-${var.subscription}"
  resource_group_name = var.subscription == "prod" ? "core-infra-prod" : "cnp-core-infra"
}

data "azurerm_key_vault_secret" "bastion_dev_ip" {
  name         = "bastion-dev-ip"
  key_vault_id = data.azurerm_key_vault.infra_vault.id
}

data "azurerm_key_vault_secret" "bastion_devops_ip" {
  name         = "bastion-devops-ip"
  key_vault_id = data.azurerm_key_vault.infra_vault.id
}

# Rules that we can't easily define in the Elastic templates, use 200>=priority>300 for these rules

resource "azurerm_network_security_rule" "bastion_es_rule" {
  count                                      = var.subscription == "prod" ? 0 : 1
  name                                       = "Bastion_To_ES"
  description                                = "Allow Bastion access for debugging elastic queries on development platforms"
  priority                                   = 200
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9200"
  source_address_prefixes                    = var.subscription == "prod" || var.subscription == "ethosldata" ? ["10.8.72.32/27"] : [ "10.11.72.32/27"]
  destination_application_security_group_ids = [data.azurerm_application_security_group.data_asg.id]
  resource_group_name                        = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name                = data.azurerm_network_security_group.cluster_nsg.name
  depends_on                                 = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_network_security_rule" "apps_rule" {
  name                                       = "App_To_ES"
  description                                = "Allow Apps to access the ElasticSearch cluster"
  priority                                   = 210
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9200"
  source_address_prefixes                    = [data.azurerm_subnet.apps.address_prefix]
  destination_application_security_group_ids = [data.azurerm_application_security_group.data_asg.id]
  resource_group_name                        = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name                = data.azurerm_network_security_group.cluster_nsg.name
  depends_on                                 = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_network_security_rule" "jenkins_rule" {
  name                                       = "Jenkins_To_ES"
  description                                = "Allow Jenkins to access the ElasticSearch cluster for testing"
  priority                                   = 220
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "9200"
  source_address_prefix                      = data.azurerm_subnet.jenkins.address_prefix
  destination_application_security_group_ids = [data.azurerm_application_security_group.data_asg.id]
  resource_group_name                        = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name                = data.azurerm_network_security_group.cluster_nsg.name
  depends_on                                 = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_network_security_rule" "bastion_ssh_rule" {
  name                        = "Bastion_To_VMs"
  description                 = "Allow Bastion SSH access overridding templates broad SSH access"
  priority                    = 230
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.subscription == "prod" || var.subscription == "ethosldata" ? ["10.8.72.32/27"] : [ "10.11.72.32/27"]
  destination_address_prefix  = data.azurerm_subnet.elastic-subnet.address_prefix
  resource_group_name         = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name = data.azurerm_network_security_group.cluster_nsg.name
  depends_on                  = ["azurerm_template_deployment.elastic-iaas"]
}

# Additional kibana-nsg rules use 300>=priority>400

resource "azurerm_network_security_rule" "kibana_tight_ssh_rule" {
  name                                       = "Bastion_only_SSH"
  description                                = "Override open SSH and limit this to Bastion only"
  priority                                   = 300
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "22"
  source_address_prefixes                    = split(",", local.bastion_ip)
  destination_application_security_group_ids = [data.azurerm_application_security_group.kibana_asg[0].id]
  resource_group_name                        = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name                = data.azurerm_network_security_group.kibana_nsg[0].name
  depends_on                                 = ["azurerm_template_deployment.elastic-iaas"]

  count = var.enable_kibana ? 1 : 0
}

resource "azurerm_network_security_rule" "kibana_tight_kibana_rule" {
  name                                       = "Bastion_only_Kibana"
  description                                = "Override open Kibana accessand limit this to Bastion only"
  priority                                   = 310
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "5601"
  source_address_prefixes                    = split(",", local.bastion_ip)
  destination_application_security_group_ids = [data.azurerm_application_security_group.kibana_asg[0].id]
  resource_group_name                        = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name                = data.azurerm_network_security_group.kibana_nsg[0].name
  depends_on                                 = ["azurerm_template_deployment.elastic-iaas"]

  count = var.enable_kibana ? 1 : 0
}

resource "azurerm_network_security_rule" "denyall_kibana_rule" {
  name                        = "DenyAllOtherTraffic"
  description                 = "Deny all traffic that is not SSH or Kibana access"
  priority                    = 400
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.elastic-resourcegroup.name
  network_security_group_name = data.azurerm_network_security_group.kibana_nsg[0].name
  depends_on                  = ["azurerm_template_deployment.elastic-iaas"]

  count = var.enable_kibana ? 1 : 0
}

#data "azurerm_virtual_machine" "dynatrace_oneagent_vm" {
#  count               = "${var.vmDataNodeCount}"
#  name                = "${var.product}-data-${count.index}"
#  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
#}
#
#resource "azurerm_virtual_machine_extension" "dynatrace_oneagent" {
#  count                = "${var.vmDataNodeCount}"
#  name                 = "oneAgentLinux"
#  virtual_machine_id   = "${data.azurerm_virtual_machine.dynatrace_oneagent_vm[count.index].id}"
#  publisher            = "dynatrace.ruxit"
#  type                 = "oneAgentLinux"
#  type_handler_version = "2.1"
#
#  settings = <<SETTINGS
#    {
#        "tenantId": "${var.dynatrace_instance}",
#        "token": "${var.dynatrace_token}",
#        "hostgroup": "${var.dynatrace_hostgroup}",
#        "installerArguments": "--set-host-group=${var.dynatrace_hostgroup} --set-infra-only=false --set-network-zone=azure.cft"
#    }
#SETTINGS
#}
#
#data "azurerm_virtual_machine" "dynatrace_oneagent_kibana" {
#  name                = "${var.product}-kibana"
#  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
#}
#
#resource "azurerm_virtual_machine_extension" "dynatrace_oneagent_kibana" {
#  name                 = "oneAgentLinux"
#  virtual_machine_id   = "${data.azurerm_virtual_machine.dynatrace_oneagent_kibana.id}"
#  publisher            = "dynatrace.ruxit"
#  type                 = "oneAgentLinux"
#  type_handler_version = "2.1"
#
#  settings = <<SETTINGS
#    {
#        "tenantId": "${var.dynatrace_instance}",
#        "token": "${var.dynatrace_token}",
#        "hostgroup": "${var.dynatrace_hostgroup}",  
#        "installerArguments": "--set-host-group=${var.dynatrace_hostgroup} --set-infra-only=false --set-network-zone=azure.cft"
#    }
#SETTINGS
#}

