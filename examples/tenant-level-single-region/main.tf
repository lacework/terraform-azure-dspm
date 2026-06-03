provider "lacework" {
  profile = "default"
}

module "lacework_azure_dspm" {
  source                    = "../.."
  lacework_integration_name = "azure-dspm-tenant-test"
  regions                   = ["East US"]

  # Deploy the scanner infrastructure (resource group, key vault, storage,
  # container app jobs) into this subscription...
  scanning_subscription_id = "/subscriptions/0252a545-04d4-4262-a82c-ceef83344237"

  # ...but scan storage accounts across the entire tenant. The scanner's managed
  # identity is granted read access at the tenant root management group, so
  # subscriptions created in the future are picked up automatically.
  integration_level = "TENANT"

  # Optionally narrow the tenant scan. The two are mutually exclusive:
  #
  # Scan only these subscriptions:
  # included_subscriptions = [
  #   "/subscriptions/11111111-1111-1111-1111-111111111111",
  #   "/subscriptions/22222222-2222-2222-2222-222222222222",
  # ]
  #
  # Or scan everything except these:
  # excluded_subscriptions = [
  #   "/subscriptions/33333333-3333-3333-3333-333333333333",
  # ]

  tags = {
    ExpectedUseThrough = "2030-05"
    CostCenter         = "4700"
    VMState            = "AlwaysOn"
    Owner              = "Lacework FortiCNAPP"
  }
}
