locals {
  # Accept either a bare UUID or a /subscriptions/<UUID> path
  scanning_subscription_id = try(
    regex("^/subscriptions/([A-Za-z0-9-]+)$", var.scanning_subscription_id)[0],
    var.scanning_subscription_id
  )

  is_tenant_level = upper(var.integration_level) == "TENANT"
  # The tenant root management group's ID equals the tenant ID. The root module
  # creates the scanner's read role and assignments at this scope for TENANT
  # integrations, so the deployment SP must be able to manage them here.
  tenant_root_mg_scope = "/providers/Microsoft.Management/managementGroups/${data.azuread_client_config.current.tenant_id}"
}

provider "azurerm" {
  features {}
  subscription_id = local.scanning_subscription_id
}

data "azurerm_subscription" "scanning" {
  subscription_id = local.scanning_subscription_id
}

data "azuread_client_config" "current" {}

data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
}

# ── Azure AD Application & Service Principal ─────────────────────────────────

resource "azuread_application" "dspm_deployment_app" {
  display_name = var.service_principal_name

  required_resource_access {
    resource_app_id = data.azuread_service_principal.msgraph.client_id
    resource_access {
      id   = "18a4783c-866b-4cc7-a460-3d5e5662c884" # Application.ReadWrite.OwnedBy
      type = "Role"
    }
  }
}

resource "azuread_service_principal" "dspm_deployment_sp" {
  client_id = azuread_application.dspm_deployment_app.client_id
}

resource "azuread_service_principal_password" "dspm_deployment_sp_password" {
  service_principal_id = "servicePrincipals/${azuread_service_principal.dspm_deployment_sp.object_id}"
  end_date             = timeadd(timestamp(), var.client_secret_expiry_duration_hours)
}

# ── Custom Role Definition ────────────────────────────────────────────────────

resource "azurerm_role_definition" "dspm_deployment_role" {
  name        = "FortiCNAPP DSPM Deployment (${var.service_principal_name})"
  scope       = data.azurerm_subscription.scanning.id
  description = "Permissions required on scanning subscription to deploy DSPM"

  permissions {
    actions = [
      "Microsoft.App/jobs/*",
      "Microsoft.App/managedEnvironments/*",
      "Microsoft.Authorization/roleAssignments/*",
      "Microsoft.Authorization/roleDefinitions/*",
      "Microsoft.KeyVault/vaults/*",
      "Microsoft.KeyVault/locations/deletedVaults/purge/*",
      "Microsoft.KeyVault/locations/operationResults/*",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*",
      "Microsoft.OperationalInsights/workspaces/*",
      "Microsoft.OperationalInsights/workspaces/sharedKeys/*",
      "Microsoft.Resources/subscriptions/resourcegroups/*",
      "Microsoft.Storage/storageAccounts/*",
      "Microsoft.Storage/storageAccounts/blobServices/*",
      "Microsoft.Storage/storageAccounts/listKeys/*",
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.scanning.id,
  ]
}

# ── Role Assignment ───────────────────────────────────────────────────────────

resource "azurerm_role_assignment" "dspm_deployment_role_assignment" {
  scope              = data.azurerm_subscription.scanning.id
  role_definition_id = azurerm_role_definition.dspm_deployment_role.role_definition_resource_id
  principal_id       = azuread_service_principal.dspm_deployment_sp.object_id
  principal_type     = "ServicePrincipal"
}

# ── Tenant-level: management-group-scoped Authorization role ─────────────────
# For TENANT integrations the root module creates the scanner's "Storage Account
# Reader" role definition and the storage-reader role assignments at the tenant
# root management group (so future subscriptions are covered automatically). The
# deployment SP therefore needs to manage role definitions and assignments at
# that scope, which the subscription-scoped role above cannot grant.

resource "azurerm_role_definition" "dspm_deployment_mg_role" {
  count = local.is_tenant_level ? 1 : 0

  name        = "FortiCNAPP DSPM Deployment MG (${var.service_principal_name})"
  scope       = local.tenant_root_mg_scope
  description = "Permissions to manage role definitions and assignments across the tenant for DSPM deployment"

  permissions {
    actions = [
      "Microsoft.Authorization/roleAssignments/*",
      "Microsoft.Authorization/roleDefinitions/*",
    ]
    not_actions = []
  }

  assignable_scopes = [
    local.tenant_root_mg_scope,
  ]
}

resource "azurerm_role_assignment" "dspm_deployment_mg_role_assignment" {
  count = local.is_tenant_level ? 1 : 0

  scope              = local.tenant_root_mg_scope
  role_definition_id = azurerm_role_definition.dspm_deployment_mg_role[0].role_definition_resource_id
  principal_id       = azuread_service_principal.dspm_deployment_sp.object_id
  principal_type     = "ServicePrincipal"
}

# ── Graph API Permission ─────────────────────────────────────────────────────

resource "azuread_app_role_assignment" "dspm_deployment_sp_graph_permission" {
  app_role_id         = "18a4783c-866b-4cc7-a460-3d5e5662c884" # Application.ReadWrite.OwnedBy
  principal_object_id = azuread_service_principal.dspm_deployment_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
