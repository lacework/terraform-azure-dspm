module "dspm_deployment_service_principal" {
  source = "./.."

  service_principal_name   = "example-dspm-deployment-sp"
  scanning_subscription_id = "my-subscription-id"
}

# Outputs
# These outputs must be defined to retrieve the credentials of the created service principal.
output "example_service_principal_client_id" {
  description = "Client ID of the DSPM deployment service principal created by the module."
  value       = module.dspm_deployment_service_principal.service_principal_client_id
}

output "example_service_principal_object_id" {
  description = "Object ID of the DSPM deployment service principal created by the module."
  value       = module.dspm_deployment_service_principal.service_principal_object_id
}

output "example_service_principal_tenant_id" {
  description = "Tenant ID where the DSPM deployment service principal was created."
  value       = module.dspm_deployment_service_principal.service_principal_tenant_id
}

output "example_service_principal_client_secret" {
  description = "Client Secret of the DSPM deployment service principal created by the module. This is a sensitive value."
  value       = module.dspm_deployment_service_principal.service_principal_client_secret
  sensitive   = true
}

output "example_dspm_deployment_role_id" {
  description = "Resource ID of the 'FortiCNAPP DSPM Deployment' custom role definition."
  value       = module.dspm_deployment_service_principal.dspm_deployment_role_id
}
