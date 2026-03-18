# Integrate Azure with Lacework for DSPM in a Single Region

The following example integrates an Azure subscription with Lacework for Data Security Posture Management (DSPM) scanning deployed in a single Azure region.

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
  regions                   = ["East US"]
  # Subscription ID to deploy DSPM within.
  scanning_subscription_id  = "/subscriptions/00000000-0000-0000-0000-000000000000"
}
```

Optionally, you can configure scan frequency, maximum file size, and datastore filters:
```hcl
module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.1"

  lacework_integration_name = "azure-dspm"
  regions                   = ["East US"]
  scanning_subscription_id  = "/subscriptions/00000000-0000-0000-0000-000000000000"

  # How often the DSPM scanner runs (valid values: 24, 72, 168, 720 hours).
  scan_frequency_hours = 168

  # Maximum file size to scan in MB (valid values: 1-50).
  max_file_size_mb = 5

  # Control which datastores to scan (filter_mode: INCLUDE, EXCLUDE, or ALL).
  datastore_filters = {
    filter_mode     = "INCLUDE"
    datastore_names = ["my-datastore"]
  }
}
```

A `tags` block can be used to add custom tags to the resources managed by the module. For example:
```hcl
module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.1"

  lacework_integration_name = "azure-dspm"
  regions                   = ["East US"]
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