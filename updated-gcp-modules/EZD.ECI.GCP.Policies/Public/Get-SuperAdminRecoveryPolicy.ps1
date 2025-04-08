function Get-SuperAdminRecoveryPolicy {
    param (
        [bool]$SuperAdminRecoveryEnabled,
        [string]$AccessToken
    )
    
    # Call the helper function to Compile current state and evaluate drift from the desired configuration
    Write-Host "Compiling current state and Calculating Drift" 
    $DriftSummary = @()
    $DriftCounter = 0
    $CurrentState = @()
    $Iteration = 0
    $PreResults = Get-ConfigurationDriftStatus -ConfigurationName "Super Admin Recovery Policy" -DriftCheckLogic {
        # Build API request
        $splat = @{
            Method = "GET"
            Uri = "https://cloudidentity.googleapis.com/v1/policies"
            Headers = @{Authorization = "Bearer $accesstoken"}
        }
        
        $Response = Invoke-WebRequest @splat
        $json = $Response.Content | ConvertFrom-Json
        $CurrentValue = (($json.policies) | Where {$_.setting.type -eq "settings/security.super_admin_account_recovery"}).setting.value.enableAccountRecovery
    
        if ($SuperAdminRecoveryEnabled -ne $CurrentValue) {
            $DriftCounter += 1
            $DriftSummary += "Super Admin Recovery Policy: CURRENT: $CurrentValue -> DESIRED: $SuperAdminRecoveryEnabled"
        }

        $CurrentState += "Super Admin Recovery Enabled: $CurrentValue"

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