provider "lacework" {
  profile = "default"
}

module "lacework_azure_dspm" {
  source                    = "../.."
  lacework_integration_name = "azure-dspm-test"
  regions                   = ["East US", "West US"]
  global_region             = "East US"
  scanning_subscription_id  = "/subscriptions/0252a545-04d4-4262-a82c-ceef83344237"
  tags = {
    ExpectedUseThrough = "2030-05"
    CostCenter         = "4700"
    VMState            = "AlwaysOn"
    Owner              = "Lacework FortiCNAPP"
  }
}
