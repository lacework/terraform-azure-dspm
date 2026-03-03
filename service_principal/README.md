# Creating a Service Principal to Deploy DSPM
We suggest creating a new Azure service principal to use specifically for deploying DSPM. You can do so by executing the terraform module in this directory as instructed in [Using the Terraform Module](#using-the-terraform-module), or by following the steps in [Manual Setup](#manual-setup).

Please note that in order to create the service principal with sufficient permissions (via the terraform module or manually by following the steps below), the az cli must be authenticated as a principal with at least the following permissions:

* `Microsoft.Authorization/roleAssignments/*`
* `Microsoft.Authorization/roleDefinitions/*`
* `Microsoft.Graph/Application.ReadWrite.All`
* `Microsoft.Graph/Directory.ReadWrite.All`

If you do not wish to create a new service principal, you can authenticate as an Azure user, as long as the user has the necessary permissions listed in the steps below.

## Using the Terraform Module
```bash
# From the root of the repository
mkdir -p tmp/service-principal
cp service_principal/example/main.tf tmp/service-principal/
cd tmp/service-principal

# Edit main.tf to set your scanning_subscription_id and service_principal_name
terraform init
terraform apply

# Retrieve the credentials
export ARM_CLIENT_ID=$(terraform output -raw example_service_principal_client_id)
export ARM_CLIENT_SECRET=$(terraform output -raw example_service_principal_client_secret)
export ARM_TENANT_ID=$(terraform output -raw example_service_principal_tenant_id)
export ARM_SUBSCRIPTION_ID="<your-scanning-subscription-id>"
```

Then deploy the DSPM module using these credentials. To tear down the service principal later, run `terraform destroy` from the `tmp/service-principal` directory.

## Manual Setup

### Create a New Service Principal
Create a new service principal named `forticnapp-dspm-deployment-sp`.
```bash
az ad sp create-for-rbac --name "forticnapp-dspm-deployment-sp"
```
In the following steps, we will assign the necessary permissions to this service principal.

### Assign Permissions to the Service Principal
1. Create a custom role that grants permissions required in the scanning subscription (i.e., the subscription where DSPM resources will be deployed).
   1. Create a json file with the following role definition and replace `<scanning-subscription-id>` with the ID of your scanning subscription.
      ```json
      // ./dspm-deployment-role.json
      {
         "Name": "FortiCNAPP DSPM Deployment",
         "Description": "Permissions required on scanning subscription to deploy DSPM",
         "Actions": [
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
            "Microsoft.Storage/storageAccounts/listKeys/*"
         ],
         "NotActions": [],
         "AssignableScopes": [
            "/subscriptions/<scanning-subscription-id>"
         ]
      }
      ```
   2. Create the custom role, passing the json file created in the previous step as the role definition.
      ```bash
      az role definition create --role-definition ./dspm-deployment-role.json
      ```
2. Assign the custom role to the previously created service principal (`forticnapp-dspm-deployment-sp`).
   1. Get the service principal object ID
      ```bash
      SP_OBJECT_ID=$(az ad sp list --display-name "forticnapp-dspm-deployment-sp" --query '[0].id' -o tsv)
      ```
   2. Assign the `FortiCNAPP DSPM Deployment` role to the service principal, scoped to the scanning subscription.
      ```bash
      az role assignment create --assignee $SP_OBJECT_ID --role "FortiCNAPP DSPM Deployment" --scope "/subscriptions/<scanning-subscription-id>"
      ```
3. Finally, grant the required `Microsoft.Graph/Application.ReadWrite.OwnedBy` permission to the service principal. For context, this permission enables the service principal to create applications as well as update and delete applications it creates.
   > [!NOTE]
   > Granting this permission requires admin consent, so the user running these commands needs to have _Global Administrator_ or _Privileged Role Administrator_ rights in the Azure AD tenant.
   1. Get the service principal application ID
      ```bash
      SP_APP_ID=$(az ad app list --display-name "forticnapp-dspm-deployment-sp" --query '[0].id' -o tsv)
      ```
   2. Add the API permission. For reference, `00000003-0000-0000-c000-000000000000` is Microsoft Graph's application ID and `18a4783c-866b-4cc7-a460-3d5e5662c884` is the `Application.ReadWrite.OwnedBy` permission ID
      ```bash
      az ad app permission add --id $SP_APP_ID \
         --api 00000003-0000-0000-c000-000000000000 \
         --api-permissions 18a4783c-866b-4cc7-a460-3d5e5662c884=Role
      ```
   3. Grant admin consent for the permission
      ```bash
      az ad app permission admin-consent --id $SP_APP_ID
      ```

Confirm that the custom role has been successfully assigned to the service principal by running the following command:
```bash
az role assignment list --all --assignee $SP_OBJECT_ID --query "[].{roleDefinitionName:roleDefinitionName,scope:scope}" -o table
```
Expected output:
```bash
RoleDefinitionName              Scope
------------------------------  ---------------------------------------------------
FortiCNAPP DSPM Deployment      /subscriptions/<scanning-subscription-id>
```

### Authenticating with the Service Principal

Once the service principal has been created and assigned the necessary permissions, you can authenticate Azure CLI using the service principal as instructed here: https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-service-principal.
