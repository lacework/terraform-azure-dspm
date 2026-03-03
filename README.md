<!-- BEGIN_TF_DOCS -->
# Terraform Azure DSPM Module

Terraform module for integrating Azure Data Security Posture Management (DSPM) with Lacework.

This module creates the necessary Azure resources for DSPM scanning, including:
- Lacework cloud account integration
- Azure Key Vault for credentials
- Service principal for authentication
- Storage account for DSPM data
- Container App Job for scheduled scanning
- Required RBAC role assignments

## Creating a Service Principal to Deploy DSPM
We suggest creating a new Azure service principal to use specifically for deploying DSPM. Please refer to the [`service_principal`](./service_principal/) directory for more information.

## Usage Examples
- [Subscription Level Single Region](./examples/subscription-level-single-region/)
- [Subscription Level Multi Region](./examples/subscription-level-multi-region/)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9 |
| azurerm | >= 3.80 |
| lacework | ~> 2.2 |
| time | >= 0.9 |

## Providers

| Name | Version |
|------|---------|
| azuread | n/a |
| azurerm | >= 3.80 |
| lacework | ~> 2.2 |
| random | n/a |
| time | >= 0.9 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_environment\_variables | Optional list of additional environment variables passed to the task. | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| global\_region | Region for global (shared) resources. Defaults to the first region in var.regions. | `string` | `""` | no |
| integration\_level | If we are integrating into a subscription or tenant. Valid values are 'SUBSCRIPTION' or 'TENANT' | `string` | n/a | yes |
| lacework\_hostname | Hostname for the Lacework account (e.g., my-tenant.lacework.net). If not provided, will use the URL associated with the default Lacework CLI profile. | `string` | `""` | no |
| lacework\_integration\_name | The name of the Lacework cloud account integration. | `string` | `"azure-dspm"` | no |
| owner\_id | Owner for service account created. Azure recommends having one | `string` | `""` | no |
| regions | List of Azure regions where DSPM scanners are deployed. | `list(string)` | n/a | yes |
| resource\_prefix | Prefix for resource names. | `string` | `"forticnapp"` | no |
| rg\_name | Name suffix for the Azure resource group that will contain all DSPM resources. | `string` | `"dspm-rg"` | no |
| scanner\_image | Docker image for the DSPM scanner | `string` | `"lacework/dspm-scanner:latest"` | no |
| scanning\_subscription\_id | SubcriptionId where FortiCNAPP DSPM is deployed. Leave blank to use the current one used by Azure Resource Manager. Show it through `az account show` | `string` | `""` | no |
| tags | Set of tags which will be added to the resources managed by the module. | `map(string)` | <pre>{<br>  "ManagedBy": "terraform"<br>}</pre> | no |
| tenant\_id | TenantId where DSPM is deployed | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| dspm\_client\_id | Client ID of our scanner's managed identity |
| dspm\_identity\_id | Fully qualified resource ID of our scanner's managed identity |
| dspm\_identity\_resource\_id | The resource ID of the DSPM identity. |
| dspm\_principal\_id | Principal ID (GUID) of our scanner's managed identity |
| key\_vault\_id | The ID of the Key Vault storing DSPM secrets. |
| key\_vault\_secret\_name | The name of the secret in Key Vault containing Lacework credentials. |
| key\_vault\_uri | The URI of the Key Vault storing DSPM secrets. |
| lacework\_hostname | Lacework hostname for the integration (e.g., my-tenant.lacework.net). |
| lacework\_integration\_id | The ID of the Lacework integration. |
| lacework\_integration\_name | The name of the integration. |
| resource\_group\_id | ID of the resource group hosting the DSPM scanner |
| resource\_group\_name | Name of the resource group hosting the DSPM scanner |
| scanner\_job\_ids | Map of region to scanner job ID. |
| scanning\_subscription\_id | The subscription where scanning resources are deployed in tenant-level integrations |
| storage\_account\_name | The blob storage account for DSPM data. |
| suffix | Suffix used to add uniqueness to resource names. |
<!-- END_TF_DOCS -->