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

data "azurerm_subnet" "elastic-subnet" {
  name                 = "${local.elasticSubnetName}"
  virtual_network_name = "${local.elasticVnetName}"
  resource_group_name  = "${azurerm_resource_group.elastic-resourcegroup.name}"
}

resource "azurerm_network_interface" "logstash" {
  name                  = "logstash-nic-${var.env}"
  location              = "${azurerm_resource_group.elastic-resourcegroup.location}"
  resource_group_name   = "${azurerm_resource_group.elastic-resourcegroup.name}"

  ip_configuration {
    name                          = "${var.product}-logstash-nic-ip-${var.env}"
    subnet_id                     = "${data.azurerm_subnet.elastic-subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "logstash" {
  name                  = "logstash-vm-${var.env}"
  location              = "${azurerm_resource_group.elastic-resourcegroup.location}"
  resource_group_name   = "${azurerm_resource_group.elastic-resourcegroup.name}"
  network_interface_ids = ["${azurerm_network_interface.logstash.id}"]
  vm_size               = "Standard_A2"

  storage_image_reference {
    id = "${data.azurerm_image.logstash.id}"
  }

  storage_os_disk {
    name              = "es-logstash-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  "os_profile" {
    computer_name = "es-logstash-os-profile"
    admin_username = "ubuntu"
    admin_password = "password123!"
//    custom_data = "${data.template_file.singlenode_userdata_script.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

//    ssh_keys {
//      path     = "/home/ubuntu/.ssh/authorized_keys"
//      key_data = "${file(var.key_path)}"
//    }
  }
}
