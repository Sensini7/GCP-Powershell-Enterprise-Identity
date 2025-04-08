function Get-TakeoutPolicy {
    param (
        [bool]$UserTakeoutEnabled,
        [bool]$ServicesTakeoutEnabled,
        [string]$AccessToken
    )
    
    # Call the helper function to Compile current state and evaluate drift from the desired configuration
    Write-Host "Compiling current state and Calculating Drift" 
    $DriftSummary = @()
    $DriftCounter = 0
    $CurrentState = @()
    $Iteration = 0
    $PreResults = Get-ConfigurationDriftStatus -ConfigurationName "Takeout Policy" -DriftCheckLogic {
        # Build API request with CEL filter
        $userSplat = @{
            Method = "GET"
            Uri = "https://cloudidentity.googleapis.com/v1/policies?pageSize=100&filter=setting.type.matches('settings/.*\\..*_takeout')"
            Headers = @{Authorization = "Bearer $accesstoken"}
        }
        
        $Response = Invoke-WebRequest @userSplat
        $json = $Response.Content | ConvertFrom-Json 
        $CurrentUserTakeoutSettings = $json.policies | Where {$_.type -eq "ADMIN"} 

        # Build API request with CEL filter
        $serviceSplat = @{
            Method = "GET"
            Uri = "https://cloudidentity.googleapis.com/v1/policies?pageSize=100&filter=setting.type=='settings/takeout.service_status'"
            Headers = @{Authorization = "Bearer $accesstoken"}
        }
        
        $Response = Invoke-WebRequest @serviceSplat
        $json = $Response.Content | ConvertFrom-Json
        $CurrentServiceTakeoutSetting = $json.policies | Select-Object -ExpandProperty Setting

        $Mapping = @{
            $true = 'ENABLED'
            $false = 'DISABLED'
        }

        # Check user takeout settings
        $UserTakeoutSettingNoDrift = $false
        foreach ($currentUserTakeoutSetting in $CurrentUserTakeoutSettings) {
            if ($currentUserTakeoutSetting.setting.value.TakeoutStatus -ne $Mapping[$UserTakeoutEnabled]) {
                $DriftCounter += 1
                $DriftSummary += "User Takeout Policy for $($currentUserTakeoutSetting.setting.type): CURRENT: $($currentUserTakeoutSetting.setting.value.TakeoutStatus) -> DESIRED: $($Mapping[$UserTakeoutEnabled])"
            } else {
                $UserTakeoutSettingNoDrift = $true
            }
        }
        if ($UserTakeoutSettingNoDrift) {
            $DriftSummary += "User Takeout Policy: No drift detected. The current state aligns with the desired state."
        }

        # Check service takeout setting
        if ($CurrentServiceTakeoutSetting.value.serviceState -ne $Mapping[$ServicesTakeoutEnabled]) {
            $DriftCounter += 1
            $DriftSummary += "Service Takeout Policy: CURRENT: $($CurrentServiceTakeoutSetting.value.serviceState) -> DESIRED: $($Mapping[$ServicesTakeoutEnabled])"
        } else {
            $DriftSummary += "Service Takeout Policy: No drift detected. The current state aligns with the desired state."
        }

        # Prepare current state display
        $CurrentState += "Service Takeout Policy:`r`n$($CurrentServiceTakeoutSetting.value.serviceState)"
        $CurrentState += "User Takeout Policy:"

        ## Get padding length for pretty logs
        $maxLength = ($CurrentUserTakeoutSettings | ForEach-Object { 
            $_.setting.type -match "settings/(.*)\..*_takeout"
            $Matches[1] 
        }).ForEach({ $_.Length }) | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum

        foreach ($currentUserTakeoutSetting in $CurrentUserTakeoutSettings) {
            $currentUserTakeoutSetting.setting.type -match "settings/(.*)\..*_takeout" | Out-Null
            $serviceName = $Matches[1]
            $paddedServiceName = $serviceName.PadRight($maxLength+1)
            $CurrentState += "$($paddedServiceName): $($currentUserTakeoutSetting.setting.value.TakeoutStatus)"
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