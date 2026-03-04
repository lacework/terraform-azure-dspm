# Integrate Azure with Lacework for DSPM Across Multiple Regions

The following example integrates an Azure subscription with Lacework for Data Security Posture Management (DSPM) scanning deployed across multiple Azure regions. A `global_region` is specified for shared resources, while scanners are deployed to each region in the `regions` list.

## Sample Code

```hcl
provider "azurerm" {
  features {}
}

provider "lacework" {}

module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.1"

  # Name of the Lacework cloud account integration.
  lacework_integration_name = "azure-dspm"
  # Regions to deploy scanners to.
  regions                   = ["East US", "West US"]
  # Region to deploy shared resources to.
  global_region             = "East US"
  # Subscription ID to deploy DSPM within.
  scanning_subscription_id  = "/subscriptions/00000000-0000-0000-0000-000000000000"
}
```

A `tags` block can be used to add custom tags to the resources managed by the module. For example:
```hcl
module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.1"

  lacework_integration_name = "azure-dspm"
  regions                   = ["East US", "West US"]
  global_region             = "East US"
  scanning_subscription_id  = "/subscriptions/00000000-0000-0000-0000-000000000000"
  
  # Tags to propagate to any resources managed by the module.
  tags = {
    ExpectedUseThrough = "2030-05"
    CostCenter         = "4700"
    VMState            = "AlwaysOn"
    Owner              = "Lacework FortiCNAPP"
  }
}
```
