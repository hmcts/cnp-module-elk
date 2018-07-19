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

variable "vNetName" {
  type = "string"
}

variable "vNetExistingResourceGroup" {
  type = "string"
}

variable "vNetClusterSubnetName" {
  type = "string"
}