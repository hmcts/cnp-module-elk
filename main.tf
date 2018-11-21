resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

resource "random_string" "password" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  number  = true
}

locals {
  artifactsBaseUrl = "https://raw.githubusercontent.com/hmcts/azure-marketplace/master/src"
  templateUrl = "${local.artifactsBaseUrl}/mainTemplate.json"
  elasticVnetName = "${var.product}-elastic-search-vnet-${var.env}"
  vNetLoadBalancerIp = "${cidrhost(data.azurerm_subnet.elastic-subnet.address_prefix, -2)}"
  securePassword = "${random_string.password.result}"
}

data "http" "template" {
  url = "${local.templateUrl}"
}

resource "azurerm_template_deployment" "elastic-iaas" {
  name                = "${azurerm_resource_group.elastic-resourcegroup.name}"
  template_body       = "${data.http.template.body}"
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  deployment_mode     = "Incremental"

  parameters = {
    # See https://github.com/elastic/azure-marketplace#parameters
    artifactsBaseUrl  = "${local.artifactsBaseUrl}"
    esClusterName     = "${var.product}-elastic-search-${var.env}"
    location          = "${azurerm_resource_group.elastic-resourcegroup.location}"

    esVersion         = "6.4.2"
    xpackPlugins      = "No"
    kibana            = "Yes"
    logstash          = "No"

    cnpEnv = "${var.env}"

    vmHostNamePrefix = "${var.product}-"

    adminUsername     = "elkadmin"
    authenticationType = "sshPublicKey"
    sshPublicKey = "${var.ssh_elastic_search_public_key}"
    securityAdminPassword = "${local.securePassword}"
    securityKibanaPassword = "${local.securePassword}"
    securityBootstrapPassword = ""
    securityLogstashPassword = "${local.securePassword}"
    securityReadPassword = "${local.securePassword}"
    securityBeatsPassword = "${local.securePassword}"

    vNetNewOrExisting = "existing"
    vNetName          = "${data.azurerm_virtual_network.core_infra_vnet.name}"
    vNetExistingResourceGroup = "${data.azurerm_virtual_network.core_infra_vnet.resource_group_name}"
    vNetLoadBalancerIp = "${local.vNetLoadBalancerIp}"
    vNetClusterSubnetName = "${data.azurerm_subnet.elastic-subnet.name}"

    vmSizeKibana = "Standard_A2"
    vmSizeDataNodes = "${var.vmSizeAllNodes}"
    vmSizeClientNodes = "${var.vmSizeAllNodes}"
    vmSizeMasterNodes = "${var.vmSizeAllNodes}"

    dataNodesAreMasterEligible = "${var.dataNodesAreMasterEligible}"

    vmDataNodeCount = "${var.vmDataNodeCount}"
    vmDataDiskCount = "${var.vmDataDiskCount}"
    vmClientNodeCount = "${var.vmClientNodeCount}"
    storageAccountType = "${var.storageAccountType}"

    esAdditionalYaml = "${var.esAdditionalYaml}"
    kibanaAdditionalYaml = "${var.kibanaAdditionalYaml}"
  }
}

data "azurerm_virtual_network" "core_infra_vnet" {
  name                 = "core-infra-vnet-${var.env}"
  resource_group_name  = "core-infra-${var.env}"
}

data "azurerm_subnet" "elastic-subnet" {
  name                 = "elasticsearch"
  virtual_network_name = "${data.azurerm_virtual_network.core_infra_vnet.name}"
  resource_group_name  = "${data.azurerm_virtual_network.core_infra_vnet.resource_group_name}"
}

data "azurerm_subnet" "apps" {
  name                 = "core-infra-subnet-3-${var.env}"
  virtual_network_name = "${data.azurerm_virtual_network.core_infra_vnet.name}"
  resource_group_name  = "${data.azurerm_virtual_network.core_infra_vnet.resource_group_name}"
}

data "azurerm_network_security_group" "cluster_nsg" {
  name = "${var.product}-cluster-nsg"
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

data "azurerm_application_security_group" "data_asg" {
  name                = "${var.product}-data-asg"
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

data "azurerm_key_vault_secret" "bastion_dev_ip" {
  name      = "bastion-dev-ip"
  vault_uri = "https://infra-vault-${var.subscription}.vault.azure.net/"
}

data "azurerm_key_vault_secret" "bastion_devops_ip" {
  name      = "bastion-devops-ip"
  vault_uri = "https://infra-vault-${var.subscription}.vault.azure.net/"
}

# Rules that we can't easily define in the Elastic templates, use 200>=priority>300 for these rules

resource "azurerm_network_security_rule" "bastion_devops_rule" {
  name                        = "BastionDevOps_To_ES_Temp"
  description                 = "Allow Bastion access for debugging (devops)"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9200"
  source_address_prefix       = "${data.azurerm_key_vault_secret.bastion_devops_ip.value}"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.elastic-resourcegroup.name}"
  network_security_group_name = "${data.azurerm_network_security_group.cluster_nsg.name}"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_network_security_rule" "bastion_dev_rule" {
  count                       = "${var.subscription == "prod" ? 0 : 1}"
  name                        = "BastionDev_To_ES_Temp"
  description                 = "Allow Bastion access for debugging (dev)"
  priority                    = 201
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9200"
  source_address_prefix       = "${data.azurerm_key_vault_secret.bastion_dev_ip.value}"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.elastic-resourcegroup.name}"
  network_security_group_name = "${data.azurerm_network_security_group.cluster_nsg.name}"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

resource "azurerm_network_security_rule" "apps_rule" {
  name                        = "App_To_ES"
  description                 = "Allow Apps to access the ElasticSearch cluster"
  priority                    = 210
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "9200"
  source_address_prefix       = "${data.azurerm_subnet.apps.address_prefix}"
  destination_application_security_group_ids = ["${data.azurerm_application_security_group.data_asg.id}"]
  resource_group_name         = "${azurerm_resource_group.elastic-resourcegroup.name}"
  network_security_group_name = "${data.azurerm_network_security_group.cluster_nsg.name}"
  depends_on = ["azurerm_template_deployment.elastic-iaas"]
}

resource "random_integer" "makeDNSupdateRunEachTime" {
  min     = 1
  max     = 99999
}

resource "null_resource" "consul" {
  triggers {
    trigger = "${azurerm_template_deployment.elastic-iaas.name}"
    forceRun = "${random_integer.makeDNSupdateRunEachTime.result}"
  }

  # register loadbalancer dns
  provisioner "local-exec" {
    # createDns.sh domain rg uri ilbIp subscription
    command = "bash -e ${path.module}/createDns.sh '${azurerm_template_deployment.elastic-iaas.name}' 'core-infra-${var.env}' '${path.module}' '${local.vNetLoadBalancerIp}' '${var.subscription}' '${azurerm_template_deployment.elastic-iaas.name}'"
  }
}

