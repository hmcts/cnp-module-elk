resource "azurerm_resource_group" "elastic-resourcegroup" {
  name     = "${var.product}-elastic-search-${var.env}"
  location = "${var.location}"

  tags = "${merge(var.common_tags,
    map("lastUpdated", "${timestamp()}")
    )}"
}

locals {
  artifactsBaseUrl = "https://raw.githubusercontent.com/elastic/azure-marketplace/6.3.0/src"
  templateUrl = "${local.artifactsBaseUrl}/mainTemplate.json"
  elasticVnetName = "elastic-search-vnet"
  elasticSubnetName = "elastic-search-subnet"
}

data "http" "template" {
  url = "${local.templateUrl}"
}

resource "azurerm_template_deployment" "elastic-iaas" {
  name                = "${var.product}-${var.env}"
  template_body       = "${data.http.template.body}"
  resource_group_name = "${azurerm_resource_group.elastic-resourcegroup.name}"
  deployment_mode     = "Incremental"

  parameters = {
    # See https://github.com/elastic/azure-marketplace#parameters
    artifactsBaseUrl  = "${local.artifactsBaseUrl}"
    esClusterName     = "${var.product}-elastic-search-${var.env}"
    location          = "${azurerm_resource_group.elastic-resourcegroup.location}"

    esVersion         = "6.3.0"
    xpackPlugins      = "No"
    kibana            = "Yes"

    adminUsername     = "elkadmin"
    adminPassword     = "password123!"
    securityAdminPassword = "password123!"
    securityKibanaPassword = "password123!"
    securityBootstrapPassword = ""
    securityLogstashPassword = "password123!"
    securityReadPassword = "password123!"

    vNetNewOrExisting = "new"
    vNetName          = "${local.elasticVnetName}"
    vNetNewAddressPrefix = "10.112.0.0/16"
    vNetLoadBalancerIp = "10.112.0.4"
    vNetClusterSubnetName = "${local.elasticSubnetName}"
    vNetNewClusterSubnetAddressPrefix = "10.112.0.0/25"

    vmSizeKibana = "Standard_A2"
    vmSizeDataNodes = "Standard_A2"
    vmSizeClientNodes = "Standard_A2"
    vmSizeMasterNodes = "Standard_A2"
  }
}

data "azurerm_subnet" "elastic-subnet" {
  name                 = "${local.elasticSubnetName}"
  virtual_network_name = "${local.elasticVnetName}"
  resource_group_name  = "${azurerm_resource_group.elastic-resourcegroup.name}"
}

resource "azurerm_network_interface" "logstash" {
  name                  = "${var.product}-logstash-nic-${var.env}"
  location              = "${azurerm_resource_group.elastic-resourcegroup.location}"
  resource_group_name   = "${azurerm_resource_group.elastic-resourcegroup.name}"

  ip_configuration {
    name                          = "${var.product}-logstash-nic-ip-${var.env}"
    subnet_id                     = "${data.azurerm_subnet.elastic-subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}
//
//resource "azurerm_virtual_machine" "logstash" {
//  name                  = "${var.product}-logstash-vm-${var.env}"
//  location              = "${azurerm_resource_group.elastic-resourcegroup.location}"
//  resource_group_name   = "${azurerm_resource_group.elastic-resourcegroup.name}"
//  network_interface_ids = ["${azurerm_network_interface.logstash.id}"]
//  vm_size               = "Standard_A2"
//
//  storage_image_reference {
//    id = "${data.azurerm_image.logstash.id}"
//  }
//
//  storage_os_disk {
//    name              = "es-logstash-osdisk"
//    caching           = "ReadWrite"
//    create_option     = "FromImage"
//    managed_disk_type = "Standard_LRS"
//  }
//
//  "os_profile" {
//    computer_name = "es-logstash-os-profile"
//    admin_username = "ubuntu"
//    admin_password = "password123!"
////    custom_data = "${data.template_file.singlenode_userdata_script.rendered}"
//  }
//
//  os_profile_linux_config {
//    disable_password_authentication = false
//
////    ssh_keys {
////      path     = "/home/ubuntu/.ssh/authorized_keys"
////      key_data = "${file(var.key_path)}"
////    }
//  }
//}
