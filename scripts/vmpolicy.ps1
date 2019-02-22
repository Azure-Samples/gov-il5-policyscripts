$env = Get-AzureRmEnvironment -Name "AzureUSGovernment"
$acc = Add-AzureRmAccount -Environment $env 

#set the resource group scope for the policy assignment
$scopeRg = Get-AzureRmResourceGroup "yourResourceGroup" -Location "usgov virginia" 

#policy definition
$policyDef = @"
{
    "if": {
        "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachines"
        },
        {
            "not": {
            "field": "Microsoft.Compute/virtualMachines/sku.name",
            "in": "[parameters('listOfAllowedSKUs')]"
            }
        }
        ]
    },
    "then": {
        "effect": "Deny"
    }
}
"@

#parameters
$policyParams = @"
{    
    "listOfAllowedSKUs": {
        "type": "Array",
        "metadata": {
        "displayName": "Allowed SKUs",
        "description": "The list of SKUs that can be specified for virtual machines.",
        "strongType": "VMSKUs"
        }
    }
}
"@

$skuList = @"
{
    "listOfAllowedSKUs": {
        "value": ["Standard_DS15_v2","Standard_D15_v2","Standard_E64is_v3","Standard_E64i_v3","Standard_F72s_v2","Standard_M128ms","Standard_NV24"] 
    }
}   
"@

$policy = New-AzureRmPolicyDefinition -Name "IL5 VM Sku Policy" `
-DisplayName "Enforce IL5 VM SKUs" `
-Description "Enforces full node skus" `
-Policy $policyDef `
-Parameter $policyParams


$assign = New-AzureRmPolicyAssignment `
-Name "Enforce IL5 VM SKU Assigment" `
-Scope $scopeRg.ResourceId `
-DisplayName "Enforce IL5 VM SKU Assignment" `
-PolicyDefinition $policy `
-PolicyParameter $skuList