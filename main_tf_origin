terraform {
   require_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~2.0"
    }
   } 
}
variable "subscription_id" {}
variable "client_id" {}
variable  "client_secret" {}
variable  "tenant_id" {}

provider "azurerm" {
    features {}
    subscription_id = var.subscription_id
    client_id = var.client_id
    client_secret = var.client_secret
    tenant_id = var.tenant_id
}
#Create  a ressource group if it doesnt exists
resource "azurerm_resource_group" "thieryResourceGroup" {
    name  = "DEMO-PPL-10-demo-az-vcs"
    location = "eastus"
}
