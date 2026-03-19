provider "lacework" {
  profile = "default"
}

module "lacework_azure_dspm" {
  source                    = "../.."
  lacework_integration_name = "azure-dspm-test"
  regions                   = ["East US", "West US"]
  global_region             = "East US"
  scanning_subscription_id  = "/subscriptions/0252a545-04d4-4262-a82c-ceef83344237"
  # Uncomment to set the scan frequency (valid values: 24, 72, 168, 720 hours)
  # scan_frequency_hours = 168

  # Uncomment to set the maximum file size to scan in MB (valid values: 1-50)
  # max_file_size_mb = 5

  # Uncomment to control which datastores to scan (filter_mode: INCLUDE, EXCLUDE, or ALL)
  # datastore_filters = {
  #   filter_mode     = "INCLUDE"
  #   datastore_names = ["my-datastore"]
  # }

  tags = {
    ExpectedUseThrough = "2030-05"
    CostCenter         = "4700"
    VMState            = "AlwaysOn"
    Owner              = "Lacework FortiCNAPP"
  }
}
