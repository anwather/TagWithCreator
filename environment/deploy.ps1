$resourceGroupName = "awfunctionsdev"            # <-- REPLACE the variable values with your own values.
$location = "australiasoutheast"                 # <-- Ensure that the location is a valid Azure location
$storageAccountName = "awfunctionsdev"           # <-- Ensure the storage account name is unique
$appServicePlanName = "AustraliaSoutheastPlan"   # <--
$appInsightsName = "awfunctionsdev"              # <--
$functionName = "awfunctionsdev"                 # <--

New-AzResourceGroup -Name $resourceGroupName -Location $location -Force -Verbose

$params = @{
    storageAccountName = $storageAccountName.ToLower()
    appServicePlanName = $appServicePlanName
    appInsightsName    = $appInsightsName
    functionName       = $functionName
}

$output = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile .\azuredeploy.json -TemplateParameterObject $params -Verbose

New-AzRoleAssignment -RoleDefinitionName "Reader" -ObjectId $output.Outputs.managedIdentityId.Value -ErrorAction SilentlyContinue -Verbose
New-AzRoleAssignment -RoleDefinitionName "Tag Contributor" -ObjectId $output.Outputs.managedIdentityId.Value -ErrorAction SilentlyContinue -Verbose

Push-Location
Set-Location ..\functions
Compress-Archive -Path * -DestinationPath ..\environment\functions.zip -Force -Verbose
Pop-Location

$file = (Get-ChildItem .\functions.zip).FullName

Publish-AzWebApp -ResourceGroupName $resourceGroupName -Name awfunctionsdev -ArchivePath $file -Verbose -Force

Remove-Item $file -Force