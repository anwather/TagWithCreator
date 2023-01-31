param($eventGridEvent, $TriggerMetadata)

#$caller = $eventGridEvent.data.claims.name
$caller = $eventGridEvent.data.claims."http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"
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

$ignore = @(
    "providers/Microsoft.Resources/deployments",
    "providers/Microsoft.Resources/tags",
    "providers/Microsoft.Network/frontdoor"
)

foreach ($case in $ignore) {
    if ($resourceId -match $case) {
        Write-Host "Skipping event as resourceId ignorelist contains: $case"
        exit;
    }
}
#Write-Host "Try add Creator tag with user: $caller"

$newTag = @{
    Creator = $caller
}

$tags = (Get-AzTag -ResourceId $resourceId)

if ($tags) {
    # Tags supported?
    if ($tags.properties) {
        # if null no tags?
        if ($tags.properties.TagsProperty) {
            if (!($tags.properties.TagsProperty.ContainsKey('Creator')) ) {
                Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $newTag | Out-Null
                Write-Host "Added Creator tag with user: $caller"
            }
            else {
                Write-Host "Creator tag already exists"
            }
        }
        else {
            Write-Host "Added Creator tag with user: $caller"
            New-AzTag -ResourceId $resourceId -Tag $newTag | Out-Null
        }
    }
    else {
        Write-Host "WARNNG! Does $resourceId does not support tags? (`$tags.properties is null)"
    }
}
else {
    Write-Host "$resourceId does not support tags"
}
