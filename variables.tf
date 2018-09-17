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
  default = "1"
}

variable "storageAccountType" {
  description = "disk storage account type"
  type = "string"
  default = "Standard"
}

