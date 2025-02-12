function Compare-SuperAdminRecoveryPolicy {
    # Build API request
    $splat = @{
      Method = "GET"
      Uri = "https://cloudidentity.googleapis.com/v1/policies"
      Headers = @{Authorization = "Bearer $accesstoken"}
    }
    
    $Response = Invoke-WebRequest @splat
    $json = $Response.Content | ConvertFrom-Json
    $CurrentValue = (($json.policies) | Where {$_.setting.type -eq "settings/security.super_admin_account_recovery"}).setting.value.enableAccountRecovery
    
    $DriftSummary = @()
    $DriftCounter = 0

    if ($SuperAdminRecoveryEnabled -ne $CurrentValue) {
        $DriftCounter += 1
        $DriftSummary += "Super Admin Recovery Policy: CURRENT: $CurrentValue -> DESIRED: $SuperAdminRecoveryEnabled"
    }
 
    # Summarize Drift
    Write-Host "===================================================================================================="
    Write-Host "DRIFT SUMMARY:"

    $DriftSummary | ForEach-Object { Write-Host $_ }

    # Summarize Current State
    Write-Host "====================================================================================================" 
    Write-Host "------------------- CURRENT STATE OF SUPER ADMIN RECOVERY (ENABLED/DISABLED) --------------------"
    Write-Host "===================================================================================================="

    Write-Host "Super Admin Recovery Enabled: $CurrentValue"

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