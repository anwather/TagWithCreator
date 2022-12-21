param($eventGridEvent, $TriggerMetadata)

$caller = $eventGridEvent.data.claims.name
if ($null -eq $caller) {
    if ($eventGridEvent.data.authorization.evidence.principalType -eq "ServicePrincipal") {
        $caller = (Get-AzADServicePrincipal -ObjectId $eventGridEvent.data.authorization.evidence.principalId).DisplayName
        if ($null -eq $caller) {
            Write-Host "MSI may not have permission to read the applications from the directory"
            $caller = $eventGridEvent.data.authorization.evidence.principalId
        }
    }
}
Write-Host "Caller: $caller"
$resourceId = $eventGridEvent.data.resourceUri
Write-Host "ResourceId: $resourceId"

if (($null -eq $caller) -or ($null -eq $resourceId)) {
    Write-Host "ResourceId or Caller is null"
    exit;
}

$ignore = @("providers/Microsoft.Resources/deployments", "providers/Microsoft.Resources/tags")

foreach ($case in $ignore) {
    if ($resourceId -match $case) {
        Write-Host "Skipping event as resourceId contains: $case"
        exit;
    }
}

$tags = (Get-AzTag -ResourceId $resourceId).Properties

if (($null -eq $tags.TagsProperty) -or !($tags.TagsProperty.ContainsKey('Creator')) ) {
    $tag = @{
        Creator = $caller
    }
    Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $tag
    Write-Host "Added creator tag with user: $caller"
}
else {
    Write-Host "Tag already exists"
}
