terraform {
  required_version = ">= 1.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
    lacework = {
      source = "lacework/lacework"
      # TODO: set version to "~> 2.3" once the lacework provider is released
      version = "99.0.0"
    }
  }
}
