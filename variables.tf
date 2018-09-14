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