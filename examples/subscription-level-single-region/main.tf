provider "lacework" {
  profile = "default"
}

# --- State migration from the old two-module layout ---

moved {
  from = module.lacework_azure_agentless_scanning_subscription_east_us
  to   = module.lacework_azure_dspm
}

# Regional resources: after the module-level move, they land at no-index.
# The new code expects ["East US"].
moved {
  from = module.lacework_azure_dspm.azurerm_log_analytics_workspace.law
  to   = module.lacework_azure_dspm.azurerm_log_analytics_workspace.law["East US"]
}
moved {
  from = module.lacework_azure_dspm.azurerm_application_insights.appi
  to   = module.lacework_azure_dspm.azurerm_application_insights.appi["East US"]
}
moved {
  from = module.lacework_azure_dspm.azurerm_container_app_environment.ca-env
  to   = module.lacework_azure_dspm.azurerm_container_app_environment.ca-env["East US"]
}
moved {
  from = module.lacework_azure_dspm.azurerm_container_app_job.scanner_job
  to   = module.lacework_azure_dspm.azurerm_container_app_job.scanner_job["East US"]
}
moved {
  from = module.lacework_azure_dspm.azurerm_role_assignment.scanner_internal_job_operator[0]
  to   = module.lacework_azure_dspm.azurerm_role_assignment.scanner_internal_job_operator["East US"]
}

module "lacework_azure_dspm" {
  source                    = "../.."
  lacework_integration_name = "azure-dspm-test"
  integration_level         = "SUBSCRIPTION"
  regions                   = ["East US"]
  scanning_subscription_id  = "/subscriptions/0252a545-04d4-4262-a82c-ceef83344237"
  tags = {
    ExpectedUseThrough = "2030-05"
    CostCenter         = "4700"
    VMState            = "AlwaysOn"
    Owner              = "Lacework FortiCNAPP"
  }
}
