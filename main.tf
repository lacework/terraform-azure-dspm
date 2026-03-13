provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.scanning_subscription_id != "" ? try(
    regex("^/subscriptions/([A-Za-z0-9-_]+)$", var.scanning_subscription_id)[0],
    var.scanning_subscription_id
  ) : null
}

data "lacework_user_profile" "current" {
}
/* used to get the az logged in user info  */
data "azurerm_client_config" "current" {}

/* used to get the current subscription info */
data "azurerm_subscription" "current" {
}

locals {
  prefix                   = var.resource_prefix
  suffix                   = random_id.suffix.hex
  global_region            = coalesce(var.global_region, var.regions[0])
  global_region_normalized = lower(replace(local.global_region, " ", ""))
  # We abbreviate the cardinal directions to help stay within resource name character limits.
  region_keys = { for r in var.regions : r =>
    replace(replace(replace(replace(replace(
      lower(replace(r, " ", "")),
      "north", "n"),
      "south", "s"),
      "east", "e"),
      "west", "w"),
    "central", "c")
  }

  lacework_hostname = length(var.lacework_hostname) > 0 ? var.lacework_hostname : data.lacework_user_profile.current.url

  owners = length(var.owner_id) > 0 ? [var.owner_id, data.azurerm_client_config.current.object_id] : [data.azurerm_client_config.current.object_id]

  tenant_id = length(var.tenant_id) > 0 ? var.tenant_id : data.azurerm_subscription.current.tenant_id
  scanning_subscription_id = var.scanning_subscription_id != "" ? try(
  regex("^/subscriptions/([A-Za-z0-9-_]+)$", var.scanning_subscription_id)[0], var.scanning_subscription_id) : data.azurerm_subscription.current.id

  scanning_subscription_id_full = "/subscriptions/${local.scanning_subscription_id}"

  resource_group_name = "${var.resource_prefix}-${var.rg_name}-${local.suffix}"
  resource_group_id   = azurerm_resource_group.rg.id

  /* Define the scope for the monitored role
  - For SUBSCRIPTION integration level, we set the scope to the set of included subscriptions specified by the user
  - For TENANT integration level, we set the scope to the root management group to enable AWLS to monitor all subscriptions in the tenant, including any created in the future.
  */
  root_management_group_scope = "/providers/Microsoft.Management/managementGroups/${local.tenant_id}"
  monitored_role_scopes       = var.integration_level == "SUBSCRIPTION" ? [local.scanning_subscription_id_full] : [local.root_management_group_scope]

  storage_account_name      = azurerm_storage_account.internal_storage_account.name
  dspm_client_id            = azurerm_user_assigned_identity.scanner_job_identity.client_id
  dspm_principal_id         = azurerm_user_assigned_identity.scanner_job_identity.principal_id
  dspm_identity_resource_id = azurerm_user_assigned_identity.scanner_job_identity.id

  integration_level = upper(var.integration_level)

  version_file   = "${abspath(path.module)}/VERSION"
  module_name    = "terrafrom-azure-dspm"
  module_version = fileexists(local.version_file) ? file(local.version_file) : ""

  key_vault_id          = azurerm_key_vault.dspm_lacework_credentials.id
  key_vault_secret_name = "${local.prefix}-secret-${local.suffix}"
  key_vault_uri         = azurerm_key_vault.dspm_lacework_credentials.vault_uri
}

resource "random_id" "suffix" {
  byte_length = 2
}

# ----------------- Lacework Cloud Integration -----------------
resource "lacework_integration_azure_dspm" "lacework_cloud_account" {
  name                = var.lacework_integration_name
  tenant_id           = local.tenant_id
  regions             = var.regions
  storage_account_url = azurerm_storage_account.internal_storage_account.primary_blob_endpoint
  blob_container_name = azurerm_storage_container.internal_storage_container.name
  credentials {
    client_id     = azuread_service_principal.data_loader.client_id
    client_secret = azuread_service_principal_password.data_loader.value
  }
  scan_frequency_hours = var.scan_frequency_hours
  max_file_size_mb     = var.max_file_size_mb
  dynamic "datastore_filters" {
    for_each = var.datastore_filters != null ? [var.datastore_filters] : []
    content {
      filter_mode     = datastore_filters.value.filter_mode
      datastore_names = datastore_filters.value.datastore_names
    }
  }
}

/* ----------------- Key Vault -----------------
Define the key vault which holds integration details
*/
resource "azurerm_key_vault" "dspm_lacework_credentials" {
  depends_on = [azurerm_resource_group.rg]

  name                       = "dspmkv${local.suffix}" // can't have dashes
  location                   = local.global_region_normalized
  resource_group_name        = local.resource_group_name
  tenant_id                  = local.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  tags                       = var.tags

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

/* Note: access policies need to be defined separately from the key vault to
avoid dependency cycles, otherwise the container app will need the key vault
id (as an env variable) to be created, while the key vault needs the container
app managed identity to create access policies.
 */
resource "azurerm_key_vault_access_policy" "access_for_dspm_scanner" {
  key_vault_id = local.key_vault_id
  tenant_id    = local.tenant_id
  object_id    = local.dspm_principal_id

  secret_permissions = [
    "Set",
    "Delete",
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "access_for_user" {
  key_vault_id = local.key_vault_id
  tenant_id    = local.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Set",
    "Delete",
    "Get",
    "List",
    "Purge",
  ]
}

# assign key vault contributor role to the service principal
resource "azurerm_role_assignment" "key_vault_dspm_scanner" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Contributor"
  principal_id         = local.dspm_principal_id
}

# assign key vault contributor role to the current user
resource "azurerm_role_assignment" "key_vault_user" {
  scope                = local.key_vault_id
  role_definition_name = "Key Vault Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "dspm_lacework_credentials" {
  depends_on = [
    lacework_integration_azure_dspm.lacework_cloud_account,
    azurerm_key_vault_access_policy.access_for_user
  ]

  # stores credentials used to authenticate to LW API server
  name         = local.key_vault_secret_name
  value        = <<EOF
   {
    "hostname": "${local.lacework_hostname}",
    "token": "${lacework_integration_azure_dspm.lacework_cloud_account.server_token}"
   }
  EOF
  key_vault_id = local.key_vault_id
}
# ----------------- End Key Vault -----------------

# ----------------- Azure Identity for Lacework Platform -----------------
resource "azuread_application" "lw" {
  display_name = "forticnapp-dspm-${local.suffix}"
  owners       = local.owners
}

resource "azuread_service_principal" "data_loader" {
  client_id                    = azuread_application.lw.client_id
  app_role_assignment_required = true
  use_existing                 = true
  owners                       = local.owners
  notes                        = "Used by Lacework data_loader to transfer analysis artifacts to Lacework"
}

resource "time_static" "password_creation" {
}

resource "azuread_service_principal_password" "data_loader" {
  service_principal_id = azuread_service_principal.data_loader.id
  end_date             = timeadd(time_static.password_creation.rfc3339, "87600h") // expires in 10 years
}

resource "azurerm_role_assignment" "storage_data_loader" {
  principal_id         = azuread_service_principal.data_loader.object_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = azurerm_storage_account.internal_storage_account.id
}

# ----------------- Basic infra -----------------
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.global_region_normalized

  tags = var.tags
}

# ----------------- Internal Storage -----------------
resource "azurerm_storage_account" "internal_storage_account" {
  depends_on = [azurerm_resource_group.rg]

  name                     = lower("dspmsa${local.suffix}") // can't have dashes
  location                 = local.global_region_normalized
  resource_group_name      = local.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}

resource "azurerm_storage_container" "internal_storage_container" {
  depends_on = [azurerm_storage_account.internal_storage_account]

  name                  = "internal"
  storage_account_id    = azurerm_storage_account.internal_storage_account.id
  container_access_type = "private"
}

# ----------------- Managed Identity -----------------
resource "azurerm_user_assigned_identity" "scanner_job_identity" {
  depends_on = [azurerm_resource_group.rg]

  name                = "${local.prefix}-job-mi-${local.suffix}"
  location            = local.global_region_normalized
  resource_group_name = local.resource_group_name

  tags = var.tags
}

# Grants reader permissions only on storage accounts.
resource "azurerm_role_definition" "storage_account_reader" {
  for_each = toset(local.monitored_role_scopes)

  name        = "Storage Account Reader (${local.resource_group_name})"
  scope       = each.value
  description = "Can list and read properties of storage accounts only."

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
    ]
    not_actions = []
  }

  assignable_scopes = [
    each.value
  ]
}

resource "azurerm_role_assignment" "storage_account_reader_assignment" {
  for_each   = toset(local.monitored_role_scopes)
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  scope              = each.value
  role_definition_id = azurerm_role_definition.storage_account_reader[each.key].role_definition_resource_id
  principal_id       = azurerm_user_assigned_identity.scanner_job_identity.principal_id
}


resource "azurerm_role_assignment" "monitored_storage_reader" {
  for_each   = toset(local.monitored_role_scopes)
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  scope                = each.value
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.scanner_job_identity.principal_id
}

resource "azurerm_role_assignment" "scanner_internal_blob_owner" {
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  scope                = azurerm_storage_account.internal_storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.scanner_job_identity.principal_id
}

resource "azurerm_role_assignment" "scanner_internal_table_owner" {
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  scope                = azurerm_storage_account.internal_storage_account.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_user_assigned_identity.scanner_job_identity.principal_id
}

resource "azurerm_role_assignment" "scanner_internal_job_operator" {
  for_each   = local.region_keys
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  scope                = azurerm_container_app_job.scanner_job[each.key].id
  role_definition_name = "Container Apps Jobs Operator"
  principal_id         = azurerm_user_assigned_identity.scanner_job_identity.principal_id
}

resource "azurerm_role_assignment" "cost_mgmt_reader" {
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azurerm_user_assigned_identity.scanner_job_identity.principal_id
}
# ----------------- Container App Job -----------------
resource "azurerm_log_analytics_workspace" "law" {
  for_each   = local.region_keys
  depends_on = [azurerm_resource_group.rg]

  name                = "${local.prefix}-law-${each.value}-${local.suffix}"
  location            = each.key
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}


# Add Application Insights for observability
resource "azurerm_application_insights" "appi" {
  for_each   = local.region_keys
  depends_on = [azurerm_resource_group.rg]

  name                = "${local.prefix}-appi-${each.value}-${local.suffix}"
  location            = each.key
  resource_group_name = local.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law[each.key].id
  application_type    = "web"

  tags = var.tags
}

resource "azurerm_container_app_environment" "ca-env" {
  for_each   = local.region_keys
  depends_on = [azurerm_resource_group.rg]

  name                       = "${local.prefix}-ca-env-${each.value}-${local.suffix}"
  location                   = each.key
  resource_group_name        = local.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law[each.key].id

  tags = var.tags
}

resource "azurerm_container_app_job" "scanner_job" {
  for_each   = local.region_keys
  depends_on = [azurerm_user_assigned_identity.scanner_job_identity]

  name                         = "dspmscanner-${each.value}-${local.suffix}"
  location                     = each.key
  resource_group_name          = local.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.ca-env[each.key].id

  replica_timeout_in_seconds = 86400
  replica_retry_limit        = 1

  template {
    container {
      name  = "dspm-scanner"
      image = var.scanner_image

      cpu    = 2
      memory = "4Gi"
      env {
        name  = "OUTPUT_BUCKET"
        value = local.storage_account_name
      }
      env {
        # Allows our task to find its managed identity
        name  = "AZURE_CLIENT_ID"
        value = local.dspm_client_id
      }
      env {
        name  = "CLOUD_PROVIDER"
        value = "AZURE"
      }
      env {
        name  = "AZURE_TENANT_ID"
        value = local.tenant_id
      }
      env {
        name  = "AZURE_INTEGRATION_LEVEL"
        value = local.integration_level
      }
      env {
        name  = "RESOURCE_GROUP"
        value = local.resource_group_name
      }
      env {
        name  = "JOB_NAME"
        value = "dspmscanner-${each.value}-${local.suffix}"
      }
      env {
        name  = "REGION"
        value = lower(replace(each.key, " ", ""))
      }
      env {
        name  = "SCANNING_ACCOUNT_ID"
        value = local.scanning_subscription_id
      }
      env {
        name  = "KEY_VAULT_URI"
        value = local.key_vault_uri
      }
      env {
        name  = "KEY_VAULT_SECRET_NAME"
        value = local.key_vault_secret_name
      }
      dynamic "env" {
        for_each = var.additional_environment_variables
        content {
          name  = env.value.name
          value = env.value.value
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [local.dspm_identity_resource_id]
  }

  schedule_trigger_config {
    cron_expression = "0 * * * *" # Runs every hour.
  }

  tags = var.tags
}
