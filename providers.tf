terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.58.0"
      configuration_aliases = [ azurerm.aks-infra, azurerm.mgmt ]
    }
  }
}