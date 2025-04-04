function Compare-APIControlSettings {
    # param (
    #     [Parameter(Mandatory)]
    #     [bool]$DesiredDomainOwnedAppsTrust,
    #     [Parameter(Mandatory)]
    #     [bool]$DesiredBlockThirdPartyAPIAccess,
    #     [Parameter(Mandatory)]
    #     [string]$accesstoken
    # )

    Write-Host "Starting Compare-APIControlSettings..."
    Write-Host "Access Token (first 20 chars): $($accesstoken.Substring(0,20))..."

    $DriftSummary = @()
    $DriftCounter = 0

    # Define the event names we want to check
    $eventNames = @(
        "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS",
        "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS",
        "BLOCK_ALL_THIRD_PARTY_API_ACCESS",
        "TRUST_DOMAIN_OWNED_OAUTH2_APPS",
        "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS"
    )

    $allEvents = @()

    foreach ($eventName in $eventNames) {
        $baseUrl = "https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/admin"
        $queryParams = @(
            "maxResults=1000",
            "eventName=$eventName",
            "startTime=2025-01-01T00:00:00Z"
        )

        $apiUrl = "$baseUrl`?$($queryParams -join '&')"

        $apiParams = @{
            Method = "GET"
            Uri = $apiUrl
            Headers = @{
                Authorization = "Bearer $accesstoken"
                'Content-Type' = 'application/json'
            }
            ErrorAction = 'SilentlyContinue'
        }

        try {
            $Response = Invoke-RestMethod @apiParams
            if ($Response.items) {
                $allEvents += $Response.items
            }
        }
        catch {
            Write-Host "API call failed for $eventName with error: $_"
            continue
        }
    }

    # Process events and get current state
    $currentState = @{}
    
    foreach ($event in $allEvents) {
        $eventType = $event.events[0].name
        $orgUnit = ($event.events[0].parameters | Where-Object { $_.name -eq "ORG_UNIT_NAME" }).value
        $date = ([DateTime]$event.id.time).ToString("yyyy-MM-ddTHH:mm:ssK")

        $setting = switch ($eventType) {
            { $_ -match "THIRD_PARTY_API_ACCESS" } { "Third Party API Access" }
            { $_ -match "DOMAIN_OWNED_OAUTH2_APPS" } { "Domain Owned Apps Trust" }
        }

        $status = switch ($eventType) {
            "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS" { "Unrestricted" }
            "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS" { "Sign-in Only" }
            "BLOCK_ALL_THIRD_PARTY_API_ACCESS" { "Blocked" }
            "TRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Trusted" }
            "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Not Trusted" }
        }

        # Only update if this is the most recent event for this setting and org unit
        $key = "$orgUnit|$setting"
        if (-not $currentState.ContainsKey($key) -or ([DateTime]$currentState[$key].Date) -lt ([DateTime]$date)) {
            $currentState[$key] = @{
                Date = $date
                Status = $status
                Actor = $event.actor.email
                IPAddress = $event.ipAddress
            }
        }
    }

    # Compare current state with desired state
    foreach ($key in $currentState.Keys) {
        $orgUnit, $setting = $key -split '\|'
        $current = $currentState[$key]

        if ($setting -eq "Domain Owned Apps Trust") {
            $desiredStatus = if ($DesiredDomainOwnedAppsTrust) { "Trusted" } else { "Not Trusted" }
            if ($current.Status -ne $desiredStatus) {
                $DriftCounter++
                $DriftSummary += "OrgUnit: $orgUnit - Domain Owned Apps Trust: CURRENT: $($current.Status) -> DESIRED: $desiredStatus"
            }
        }
        elseif ($setting -eq "Third Party API Access") {
            $desiredStatus = if ($DesiredBlockThirdPartyAPIAccess) { "Blocked" } else { "Current setting acceptable" }
            if ($DesiredBlockThirdPartyAPIAccess -and $current.Status -ne "Blocked") {
                $DriftCounter++
                $DriftSummary += "OrgUnit: $orgUnit - Third Party API Access: CURRENT: $($current.Status) -> DESIRED: Blocked"
            }
        }
    }

    # Display Current State
    Write-Host "===================================================================================================="
    Write-Host "------------------- CURRENT STATE OF API CONTROLS --------------------"
    Write-Host "===================================================================================================="

    foreach ($key in $currentState.Keys) {
        $orgUnit, $setting = $key -split '\|'
        $current = $currentState[$key]
        
        Write-Host "`nOrganization Unit: $orgUnit"
        Write-Host "Setting: $setting"
        Write-Host "Current Status: $($current.Status)"
        Write-Host "Last Changed: $($current.Date)"
        Write-Host "Changed By: $($current.Actor)"
        Write-Host "IP Address: $($current.IPAddress)"
        Write-Host "-------------------------"
    }

    # Display Drift Summary
    Write-Host "===================================================================================================="
    Write-Host "DRIFT SUMMARY:"
    if ($DriftSummary.Count -gt 0) {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No drift detected. All API Controls match desired state."
    }

    $Iteration += 1

    Write-Host "===================================================================================================="
    if ($DriftCounter -gt 0) { 
        Write-Host "DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE"
    } else {
        Write-Host "NO DRIFT DETECTED: THE CURRENT STATE ALIGNS WITH THE DESIRED STATE"
    }
    Write-Host "===================================================================================================="

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}

# Export-ModuleMember -Function Compare-APIControlSettings