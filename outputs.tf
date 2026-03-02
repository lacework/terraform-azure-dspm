output "storage_account_name" {
  value       = azurerm_storage_account.internal_storage_account.name
  description = "The blob storage account for DSPM data."
}

output "dspm_client_id" {
  value       = azurerm_user_assigned_identity.scanner_job_identity.client_id
  description = "Client ID of our scanner's managed identity"
}

output "dspm_principal_id" {
  value       = azurerm_user_assigned_identity.scanner_job_identity.principal_id
  description = "Principal ID (GUID) of our scanner's managed identity"
}

output "dspm_identity_id" {
  value       = azurerm_user_assigned_identity.scanner_job_identity.id
  description = "Fully qualified resource ID of our scanner's managed identity"
}

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the resource group hosting the DSPM scanner"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "ID of the resource group hosting the DSPM scanner"
}

output "suffix" {
  value       = random_id.suffix.hex
  description = "Suffix used to add uniqueness to resource names."
}

output "scanning_subscription_id" {
  value       = local.scanning_subscription_id
  description = "The subscription where scanning resources are deployed in tenant-level integrations"
}

output "lacework_hostname" {
  value       = local.lacework_hostname
  description = "Lacework hostname for the integration (e.g., my-tenant.lacework.net)."
}

output "lacework_integration_name" {
  value       = var.lacework_integration_name
  description = "The name of the integration."
}

output "lacework_integration_id" {
  value       = lacework_integration_azure_dspm.lacework_cloud_account.id
  description = "The ID of the Lacework integration."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.dspm_lacework_credentials.vault_uri
  description = "The URI of the Key Vault storing DSPM secrets."
}

output "key_vault_secret_name" {
  value       = local.key_vault_secret_name
  description = "The name of the secret in Key Vault containing Lacework credentials."
}

output "key_vault_id" {
  value       = azurerm_key_vault.dspm_lacework_credentials.id
  description = "The ID of the Key Vault storing DSPM secrets."
}

output "dspm_identity_resource_id" {
  value       = azurerm_user_assigned_identity.scanner_job_identity.id
  description = "The resource ID of the DSPM identity."
}

output "scanner_job_ids" {
  value       = { for r, job in azurerm_container_app_job.scanner_job : r => job.id }
  description = "Map of region to scanner job ID."
}
