# Integrate Azure with Lacework for DSPM at the Tenant Level

The following example integrates an entire Azure tenant with Lacework for Data Security Posture Management (DSPM) scanning. The scanner infrastructure is deployed into a single subscription, but storage accounts are scanned across **every** subscription in the tenant. Because the scanner's managed identity is granted read access at the tenant root management group, subscriptions created in the future are picked up automatically.

> **Prerequisite:** Tenant-level deployment creates a role definition and role assignments at the tenant root management group. The identity running Terraform (or the deployment service principal — see the `service_principal` submodule, which must be created with `integration_level = "TENANT"`) needs `Microsoft.Authorization/roleDefinitions/*` and `Microsoft.Authorization/roleAssignments/*` at that scope.

## Sample Code

```hcl
provider "azurerm" {
  features {}
}

provider "lacework" {}

module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.2"

  lacework_integration_name = "azure-dspm"
  regions                   = ["East US"]

  # Subscription that hosts the scanner infrastructure.
  scanning_subscription_id = "/subscriptions/00000000-0000-0000-0000-000000000000"

  # Scan the whole tenant.
  integration_level = "TENANT"
}
```

## Narrowing the tenant scan

By default a tenant-level integration scans every subscription. You can narrow this with **either** an include list **or** an exclude list (the two are mutually exclusive).

Scan only specific subscriptions:
```hcl
module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.2"

  lacework_integration_name = "azure-dspm"
  regions                   = ["East US"]
  scanning_subscription_id  = "/subscriptions/00000000-0000-0000-0000-000000000000"
  integration_level         = "TENANT"

  included_subscriptions = [
    "/subscriptions/11111111-1111-1111-1111-111111111111",
    "/subscriptions/22222222-2222-2222-2222-222222222222",
  ]
}
```

Scan the whole tenant except specific subscriptions:
```hcl
module "lacework_azure_dspm" {
  source  = "lacework/dspm/azure"
  version = "~> 0.2"

  lacework_integration_name = "azure-dspm"
  regions                   = ["East US"]
  scanning_subscription_id  = "/subscriptions/00000000-0000-0000-0000-000000000000"
  integration_level         = "TENANT"

  excluded_subscriptions = [
    "/subscriptions/33333333-3333-3333-3333-333333333333",
  ]
}
```
