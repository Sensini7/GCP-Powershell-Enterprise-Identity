function Compare-TakeoutPolicy {
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
    
    $DriftSummary = @()
    $DriftCounter = 0

    $Mapping = @{
        $true = 'ENABLED'
        $false = 'DISABLED'
    }

    foreach ($currentUserTakeoutSetting in $CurrentUserTakeoutSettings) {
        if ($currentUserTakeoutSetting.setting.value.TakeoutStatus -ne $Mapping[$UserTakeoutEnabled]) {
            $DriftCounter += 1
            $DriftSummary += "User Takeout Policy for $($currentUserTakeoutSetting.setting.type): CURRENT: $($currentUserTakeoutSetting.setting.value.TakeoutStatus) -> DESIRED: $($Mapping[$UserTakeoutEnabled])"
        }
    }

    if ($CurrentServiceTakeoutSetting.value.serviceState -ne $Mapping[$ServicesTakeoutEnabled]) {
        $DriftCounter += 1
        $DriftSummary += "Service Takeout Policy: CURRENT: $($CurrentServiceTakeoutSetting.value.serviceState) -> DESIRED: $($Mapping[$ServicesTakeoutEnabled])"
    }
 
    # Summarize Drift
    Write-Host "===================================================================================================="
    Write-Host "DRIFT SUMMARY:"

    $DriftSummary | ForEach-Object { Write-Host $_ }

    # Summarize Current State
    Write-Host "====================================================================================================" 
    Write-Host "------------------- CURRENT STATE OF TAKEOUT POLICY (ENABLED/DISABLED) --------------------"
    Write-Host "===================================================================================================="

    Write-Host "Service Takeout Policy:`r`n$($CurrentServiceTakeoutSetting.value.serviceState)"

    Write-Host "User Takeout Policy:"

    ## Get padding length for pretty logs
    $maxLength = ($CurrentUserTakeoutSettings `
                    | ForEach-Object { 
                        $_.setting.type -match "settings/(.*)\..*_takeout"; $Matches[1] 
                    }).ForEach({ $_.Length }) `
                    | Measure-Object -Maximum `
                    | Select-Object -ExpandProperty Maximum

    
    foreach ($currentUserTakeoutSetting in $CurrentUserTakeoutSettings) {
        $currentUserTakeoutSetting.setting.type -match "settings/(.*)\..*_takeout" | Out-Null
        $serviceName = $Matches[1]
        $paddedServiceName = $serviceName.PadRight($maxLength+1)
        Write-Host "$($paddedServiceName): $($currentUserTakeoutSetting.setting.value.TakeoutStatus)"
    }

    $Iteration += 1

    Write-Host "===================================================================================================="
    if ($DriftCounter -gt 0) { 
        Write-Host "DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE FOR SOME DOMAINS"
    }
    else {
        Write-Host "NO DRIFT DETECTED: THE CURRENT STATE ALIGNS WITH THE DESIRED STATE FOR ALL DOMAINS"
    }
    Write-Host "===================================================================================================="

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}