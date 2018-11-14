variable "product" {
  type = "string"
}

variable "location" {
  type = "string"
  default = "UK South"
}

variable "env" {
  type = "string"
}

variable "subscription" {
  type    = "string"
}

variable "common_tags" {
  type = "map"
}

variable "dataNodesAreMasterEligible" {
  type = "string"
  default = "Yes"
}

variable "vmDataNodeCount" {
  description = "number of data nodes"
  type = "string"
  default = "1"
}

variable "vmDataDiskCount" {
  description = "number of data node's disks"
  type = "string"
  default = "1"
}

variable "vmClientNodeCount" {
  description = "number of client nodes"
  type = "string"
  default = "0"
}

variable "storageAccountType" {
  description = "disk storage account type"
  type = "string"
  default = "Standard"
}

variable "vmSizeAllNodes" {
  description = "vm size for all the cluster nodes"
  type = "string"
  default = "Standard_A2"
}

variable "esAdditionalYaml" {
  description = "Additional configuration for Elasticsearch yaml configuration file. Each line must be separated by a \n"
  type = "string"
  default = ""
}

variable "kibanaAdditionalYaml" {
  description = "Additional configuration for Kibana yaml configuration file. Each line must be separated by a \n"
  type = "string"
  default = ""
}

