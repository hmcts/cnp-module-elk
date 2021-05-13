variable "product" {}

variable "location" {
  default = "UK South"
}

variable "env" {}

variable "subscription" {}

variable "common_tags" {
  type = map
}

variable "dataNodesAreMasterEligible" {
  type    = bool
  default = true
}

variable "vmDataNodeCount" {
  description = "number of data nodes"
  type        = number
  default     = 1
}

variable "vmDataDiskCount" {
  description = "number of data node's disks"
  type        = number
  default     = 1
}

variable "vmClientNodeCount" {
  description = "number of client nodes"
  type        = number
  default     = 1
}

variable "storageAccountType" {
  description = "disk storage account type"
  default     = "Standard"
}

variable "vmSizeAllNodes" {
  description = "vm size for all the cluster nodes"
  default     = "Standard_D2_v2"
}

variable "ssh_elastic_search_public_key" {
  description = "pub key used to ssh into the cluster nodes"
}

variable "esAdditionalYaml" {
  description = "Additional configuration for Elasticsearch yaml configuration file. Each line must be separated by a \n"
  default     = "action.auto_create_index: .security*,.monitoring*,.watches,.triggered_watches,.watcher-history*,.logstash_dead_letter,.ml*\nxpack.monitoring.collection.enabled: true\nscript.allowed_types: none\nscript.allowed_contexts: none\n"
}

variable "kibanaAdditionalYaml" {
  description = "Additional configuration for Kibana yaml configuration file. Each line must be separated by a \n"
  default     = "console.enabled: false\n"
}

variable "logAnalyticsId" {
  description = "Log Analytics ID, enables VM logging to Log Analytics (blank disables)"
  default     = ""
}

variable "logAnalyticsKey" {
  description = "Log Analytics secret key, enables VM logging to Log Analytics"
  default     = ""
}

variable "dataNodeAcceleratedNetworking" {
  description = "Whether to enable accelerated networking for data nodes, which enables single root I/O virtualization (SR-IOV) to a VM, greatly improving its networking performance. Valid values are Default, Yes, No"
  default     = "No"
}

variable "dynatrace_instance" {
  default = ""
}

variable "dynatrace_hostgroup" {
  default = ""
}

variable "dynatrace_token" {
  default = ""
}

variable "enable_kibana" {
  type    = bool
  default = true
}

variable "enable_logstash" {
  type    = bool
  default = false
}

variable "alerts_email" {
  description = "Email for sending alerts"
}

variable "vmHostNamePrefix" {}