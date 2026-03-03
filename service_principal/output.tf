output "service_principal_client_id" {
  description = "The Client ID (Application ID) of the created service principal."
  value       = azuread_application.dspm_deployment_app.client_id
}

output "service_principal_object_id" {
  description = "The Object ID of the created service principal."
  value       = azuread_service_principal.dspm_deployment_sp.object_id
}

output "service_principal_tenant_id" {
  description = "The Tenant ID where the service principal was created."
  value       = data.azuread_client_config.current.tenant_id
}

output "service_principal_client_secret" {
  description = "The Client Secret for the service principal. Store this securely."
  value       = azuread_service_principal_password.dspm_deployment_sp_password.value
  sensitive   = true
}

output "dspm_deployment_role_id" {
  description = "The resource ID of the 'FortiCNAPP DSPM Deployment' custom role definition."
  value       = azurerm_role_definition.dspm_deployment_role.id
}
