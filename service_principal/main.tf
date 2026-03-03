locals {
  # Accept either a bare UUID or a /subscriptions/<UUID> path
  scanning_subscription_id = try(
    regex("^/subscriptions/([A-Za-z0-9-]+)$", var.scanning_subscription_id)[0],
    var.scanning_subscription_id
  )
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
      "Microsoft.Insights/components/*",
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

# ── Graph API Permission ─────────────────────────────────────────────────────

resource "azuread_app_role_assignment" "dspm_deployment_sp_graph_permission" {
  app_role_id         = "18a4783c-866b-4cc7-a460-3d5e5662c884" # Application.ReadWrite.OwnedBy
  principal_object_id = azuread_service_principal.dspm_deployment_sp.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}
