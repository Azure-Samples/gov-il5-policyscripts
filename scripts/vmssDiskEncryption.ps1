#Set environment and connect to Azure Subscription    
$env = Get-AzureRmEnvironment -Name "AzureUSGovernment"
$acc = Add-AzureRmAccount -Environment $env

#USAGE NOTE: This script assumes you have created a VM Scale set and selected Managed Disks before beginning.

#set params for scaleset
$rgName = "vmssRg" #use the same RG your VMSS was deployed to for this sample.
$location = "USGOV Texas"
$vmssName = "vmssName"

#set params for keyvault:
$vaultName = "akvName"
$kvrgName = "akvRg"

#register the provider and wait for completion (can take up to 10 minutes)
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName "UnifiedDiskEncryption"

#loop until completed
$res = $false
while ($res -eq $false)
{
 $features = Get-AzureRmProviderFeature
 foreach ($f in $features) {
    "Checking $($f.featurename)"
    if ($f.featurename -eq "UnifiedDiskEncryption")
    {
       $res = $true
       "Found. Continuing.."
       break
    }
    else
    {
        "Current result: $res.."
        $res = $false        
    }
 }  
  
 if ($res -eq $false) { 
    Start-Sleep -Seconds 5
 }
} 

#After completed, re-register the feature to the compute provider
Get-AzureRmProviderFeature -ProviderNamespace "Microsoft.Compute" -FeatureName "UnifiedDiskEncryption"
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute

#Create a keyvault & Key to support the encryption
#    $rg = get-AzureRmResourceGroup -Name $rgName -Location $location
#    $kv = New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $rgName -Location $location -EnabledForDiskEncryption


#use an existing keyvault - 
Set-AzureRmKeyVaultAccessPolicy -VaultName $vaultName -EnabledForDiskEncryption


#Enable ADE on the scale set.
$diskEncryptionKeyVaultUrl=(Get-AzureRmKeyVault -ResourceGroupName $kvrgName -Name $vaultName).VaultUri
$keyVaultResourceId=(Get-AzureRmKeyVault -ResourceGroupName $kvrgName -Name $vaultName).ResourceId

Set-AzureRmVmssDiskEncryptionExtension -ResourceGroupName $rgName -VMScaleSetName $vmssName -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $keyVaultResourceId –VolumeType "All"

#check encryption progress..:
$isEncrypted = $false

while ($isEncrypted -eq $false) 
{
$res = Get-AzureRmVmssDiskEncryption -ResourceGroupName $rgName -VMScaleSetName $vmssName
"Current state: $($res.EncryptionEnabled)"
if ($res.EncryptionEnabled -eq $false)
{        
    $isEncrypted = $false
    start-sleep -Seconds 5
}
else 
{
    "New state: $($res.EncryptionEnabled) .. exiting"
    $isEncrypted = $true
    break
}
}
