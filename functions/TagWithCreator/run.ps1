param($eventGridEvent, $TriggerMetadata)

$caller = $eventGridEvent.data.claims.name
if ($null -eq $caller) {
    if ($eventGridEvent.data.authorization.evidence.principalType = "ServicePrincipal") {
        Write-Host "Raw Caller Id: $($eventGridEvent.data.authorization.evidence.principalId)"
        $caller = (Get-AzADServicePrincipal -ObjectId $eventGridEvent.data.authorization.evidence.principalId).DisplayName
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

if (!($tags.TagsProperty.ContainsKey('Creator')) -or ($null -eq $tags)) {
    $tag = @{
        Creator = $caller
    }
    Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $tag
    Write-Host "Added creator tag with user: $caller"
}
else {
    Write-Host "Tag already exists"
}
