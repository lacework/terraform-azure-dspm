# State migration helpers for existing deployments upgrading from the
# multi-module (global/regional) layout to the single-module layout.
#
# These moved blocks handle the [0] index removal for resources that
# previously used `count = var.global ? 1 : 0` and are now unconditional.
#
# For regional resources (law, appi, ca-env, scanner_job), moved blocks
# cannot help because the new for_each keys depend on user-specific region
# names. Use `terraform state mv` manually for those, e.g.:
#   terraform state mv 'module.dspm.azurerm_log_analytics_workspace.law' \
#     'module.dspm.azurerm_log_analytics_workspace.law["East US"]'
#
# For scanner_internal_job_operator, it changed from count to for_each:
#   terraform state mv 'module.dspm.azurerm_role_assignment.scanner_internal_job_operator[0]' \
#     'module.dspm.azurerm_role_assignment.scanner_internal_job_operator["East US"]'

moved {
  from = lacework_integration_azure_dspm.lacework_cloud_account[0]
  to   = lacework_integration_azure_dspm.lacework_cloud_account
}

moved {
  from = azurerm_key_vault.dspm_lacework_credentials[0]
  to   = azurerm_key_vault.dspm_lacework_credentials
}

moved {
  from = azurerm_key_vault_access_policy.access_for_sidekick[0]
  to   = azurerm_key_vault_access_policy.access_for_sidekick
}

moved {
  from = azurerm_key_vault_access_policy.access_for_user[0]
  to   = azurerm_key_vault_access_policy.access_for_user
}

moved {
  from = azurerm_role_assignment.key_vault_sidekick[0]
  to   = azurerm_role_assignment.key_vault_sidekick
}

moved {
  from = azurerm_role_assignment.key_vault_user[0]
  to   = azurerm_role_assignment.key_vault_user
}

moved {
  from = azurerm_key_vault_secret.dspm_lacework_credentials[0]
  to   = azurerm_key_vault_secret.dspm_lacework_credentials
}

moved {
  from = azuread_application.lw[0]
  to   = azuread_application.lw
}

moved {
  from = azuread_service_principal.data_loader[0]
  to   = azuread_service_principal.data_loader
}

moved {
  from = time_static.password_creation[0]
  to   = time_static.password_creation
}

moved {
  from = azuread_service_principal_password.data_loader[0]
  to   = azuread_service_principal_password.data_loader
}

moved {
  from = azurerm_role_assignment.storage_data_loader[0]
  to   = azurerm_role_assignment.storage_data_loader
}

moved {
  from = azurerm_resource_group.rg[0]
  to   = azurerm_resource_group.rg
}

moved {
  from = azurerm_storage_account.internal_storage_account[0]
  to   = azurerm_storage_account.internal_storage_account
}

moved {
  from = azurerm_storage_container.internal_storage_container[0]
  to   = azurerm_storage_container.internal_storage_container
}

moved {
  from = azurerm_user_assigned_identity.scanner_job_identity[0]
  to   = azurerm_user_assigned_identity.scanner_job_identity
}

moved {
  from = azurerm_role_assignment.scanner_internal_blob_owner[0]
  to   = azurerm_role_assignment.scanner_internal_blob_owner
}

moved {
  from = azurerm_role_assignment.scanner_internal_table_owner[0]
  to   = azurerm_role_assignment.scanner_internal_table_owner
}

moved {
  from = azurerm_role_assignment.cost_mgmt_reader[0]
  to   = azurerm_role_assignment.cost_mgmt_reader
}
