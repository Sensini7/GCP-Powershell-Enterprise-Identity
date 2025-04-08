function Get-APIControlSettings {
    param (
        [Parameter(Mandatory)]
        [string]$AccessToken,
        [Parameter(Mandatory)]
        [bool]$DesiredDomainOwnedAppsTrust,
        [Parameter(Mandatory)]
        [bool]$DesiredBlockThirdPartyAPIAccess
    )
    
    # Call the helper function to Compile current state and evaluate drift
    Write-Host "Compiling current state and Calculating Drift" 
    $DriftSummary = @()
    $DriftCounter = 0
    $CurrentState = @()
    $Iteration = 0
    
    $PolicyConfigurationName = "API Control Settings"
    $PreResults = Get-ConfigurationDriftStatus -ConfigurationName $PolicyConfigurationName -DriftCheckLogic {
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
                    Authorization = "Bearer $AccessToken"
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
        $stateMap = @{}
        
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

            $key = "$orgUnit|$setting"
            if (-not $stateMap.ContainsKey($key) -or ([DateTime]$stateMap[$key].Date) -lt ([DateTime]$date)) {
                $stateMap[$key] = @{
                    Date = $date
                    Status = $status
                    Actor = $event.actor.email
                    IPAddress = $event.ipAddress
                }
            }
        }

        ## Get indentation for output alignment
        $maxLength = ($PolicyConfigurationName | Measure-Object -Maximum -Property Length).Maximum
        $paddedSettingName = $PolicyConfigurationName.PadRight($maxLength + 1)

        # Compare current state with desired state
        foreach ($key in $stateMap.Keys) {
            $orgUnit, $setting = $key -split '\|'
            $current = $stateMap[$key]
            
            $CurrentState += "$($paddedSettingName): $orgUnit - $setting - $($current.Status)"

            if ($setting -eq "Domain Owned Apps Trust") {
                $desiredStatus = if ($DesiredDomainOwnedAppsTrust) { "Trusted" } else { "Not Trusted" }
                if ($current.Status -ne $desiredStatus) {
                    $DriftCounter++
                    $DriftSummary += "$($paddedSettingName): CURRENT: $($current.Status) -> DESIRED: $desiredStatus"
                }
            }
            elseif ($setting -eq "Third Party API Access") {
                if ($DesiredBlockThirdPartyAPIAccess -and $current.Status -ne "Blocked") {
                    $DriftCounter++
                    $DriftSummary += "$($paddedSettingName): CURRENT: $($current.Status) -> DESIRED: Blocked"
                }
            }
        }

        return @{
            "DriftCounter" = $DriftCounter
            "DriftSummary" = $DriftSummary
            "CurrentState" = $CurrentState
        }
    }
    
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $DriftSummary = $PreResults["DriftSummary"]

    Write-Host "THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE"
    if ($DriftCounter -gt 0) {
        return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
    } else {
        return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
    }
}