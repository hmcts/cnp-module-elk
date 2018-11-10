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
    logstash          = "Yes"

    cnpEnv = "${var.env}"

    vmHostNamePrefix = "${var.product}-"

    #TODO move from password to sshPublicKey
    adminUsername     = "elkadmin"
    adminPassword     = "${local.securePassword}"
    securityAdminPassword = "${local.securePassword}"
    securityKibanaPassword = "${local.securePassword}"
    securityBootstrapPassword = ""
    securityLogstashPassword = "${local.securePassword}"
    securityReadPassword = "${local.securePassword}"
    securityBeatsPassword = "${local.securePassword}"
    securityLogstashPassword = "${local.securePassword}"

    vNetNewOrExisting = "existing"
    vNetName          = "${data.azurerm_virtual_network.core_infra_vnet.name}"
    vNetExistingResourceGroup = "${data.azurerm_virtual_network.core_infra_vnet.resource_group_name}"
    vNetLoadBalancerIp = "${local.vNetLoadBalancerIp}"
    vNetClusterSubnetName = "${data.azurerm_subnet.elastic-subnet.name}"

    vmSizeKibana = "Standard_A2"
    vmSizeDataNodes = "${var.vmSizeAllNodes}"
    vmSizeClientNodes = "${var.vmSizeAllNodes}"
    vmSizeMasterNodes = "${var.vmSizeAllNodes}"
    vmSizeLogstash = "${var.vmSizeAllNodes}"

    dataNodesAreMasterEligible = "${var.dataNodesAreMasterEligible}"

    vmDataNodeCount = "${var.vmDataNodeCount}"
    vmDataDiskCount = "${var.vmDataDiskCount}"
    vmClientNodeCount = "${var.vmClientNodeCount}"
    storageAccountType = "${var.storageAccountType}"

    esAdditionalYaml = "${var.esAdditionalYaml}"

    logstashConf      = "${var.logstashConf}"
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

