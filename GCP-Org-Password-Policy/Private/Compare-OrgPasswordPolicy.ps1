function Compare-OrgPasswordPolicy {
    # param(
    #     [Parameter(Mandatory)]
    #     [string]$accesstoken,
    #     [Parameter(Mandatory)]
    #     [bool]$DesiredPasswordStrengthEnforced,
    #     [Parameter(Mandatory)]
    #     [int]$DesiredMinLength,
    #     [Parameter(Mandatory)]
    #     [int]$DesiredMaxLength,
    #     [Parameter(Mandatory)]
    #     [bool]$DesiredEnforceNextSignIn,
    #     [Parameter(Mandatory)]
    #     [bool]$DesiredPasswordReuseAllowed,
    #     [Parameter(Mandatory)]
    #     [int]$DesiredPasswordExpirationDays
    # )

    # Build API request with specific filter
    $splat = @{
        Method = "GET"
        Uri = "https://cloudidentity.googleapis.com/v1/policies?pageSize=100&filter=setting.type=='settings/security.password'"
        Headers = @{Authorization = "Bearer $accesstoken"}
    }
    
    $Response = Invoke-WebRequest @splat
    $json = $Response.Content | ConvertFrom-Json
    
    # Get all password policies
    $passwordPolicies = $json.policies | Where-Object { 
        $_.setting.type -eq "settings/security.password"
    }

    $DriftSummary = @()
    $DriftCounter = 0
    
    # Mapping for enabled/disabled states
    $Mapping = @{
        $true = 'ENABLED'
        $false = 'DISABLED'
    }

    # Calculate drift for each policy
    foreach ($policy in $passwordPolicies) {
        $settings = $policy.setting.value

        # Compare settings and track drift
        if ($settings.allowedStrength -ne ($Mapping[$DesiredPasswordStrengthEnforced])) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Password Strength: CURRENT: $($settings.allowedStrength) -> DESIRED: $($Mapping[$DesiredPasswordStrengthEnforced])"
        }

        if ($settings.minimumLength -ne $DesiredMinLength) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Minimum Length: CURRENT: $($settings.minimumLength) -> DESIRED: $DesiredMinLength"
        }

        if ($settings.maximumLength -ne $DesiredMaxLength) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Maximum Length: CURRENT: $($settings.maximumLength) -> DESIRED: $DesiredMaxLength"
        }

        if ($settings.enforceRequirementsAtLogin -ne $DesiredEnforceNextSignIn) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Enforce at Login: CURRENT: $($Mapping[$settings.enforceRequirementsAtLogin]) -> DESIRED: $($Mapping[$DesiredEnforceNextSignIn])"
        }

        if ($settings.allowReuse -ne $DesiredPasswordReuseAllowed) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Password Reuse: CURRENT: $($Mapping[$settings.allowReuse]) -> DESIRED: $($Mapping[$DesiredPasswordReuseAllowed])"
        }

        # Convert expirationDuration from "Xs" format to days
        $currentExpirationDays = if ($settings.expirationDuration -eq '0s') { 0 } else {
            [int]($settings.expirationDuration -replace 's$', '') / 86400
        }

        if ($currentExpirationDays -ne $DesiredPasswordExpirationDays) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Password Expiration Days: CURRENT: $currentExpirationDays -> DESIRED: $DesiredPasswordExpirationDays"
        }
    }

    # Summarize Drift
    Write-Host "===================================================================================================="
    Write-Host "DRIFT SUMMARY:"

    if ($DriftSummary.Count -gt 0) {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    } else {
        Write-Host "No drift detected. All password policies match desired state."
    }

    # Summarize Current State
    Write-Host "====================================================================================================" 
    Write-Host "------------------- CURRENT STATE OF PASSWORD POLICIES --------------------"
    Write-Host "===================================================================================================="

    foreach ($policy in $passwordPolicies) {
        $settings = $policy.setting.value
        $policyName = $policy.name.PadRight($maxLength+1)
        
        Write-Host "`nPolicy: $policyName"
        Write-Host "Organization Unit: $($policy.policyQuery.orgUnit)"
        Write-Host "Applies to: $($policy.policyQuery.query)"
        Write-Host "`nPassword Requirements:"
        Write-Host "Password Strength: $($settings.allowedStrength)"
        Write-Host "Minimum Length: $($settings.minimumLength) characters"
        Write-Host "Maximum Length: $($settings.maximumLength) characters"
        Write-Host "Enforce at Login: $($settings.enforceRequirementsAtLogin)"
        Write-Host "Allow Password Reuse: $($settings.allowReuse)"
        Write-Host "Password Expiration: $(if ($settings.expirationDuration -eq '0s') { 'Never' } else { $settings.expirationDuration })"
        Write-Host "-------------------------"
    }

    $Iteration += 1

    Write-Host "===================================================================================================="
    if ($DriftCounter -gt 0) { 
        Write-Host "DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE FOR SOME POLICIES"
    } else {
        Write-Host "NO DRIFT DETECTED: THE CURRENT STATE ALIGNS WITH THE DESIRED STATE FOR ALL POLICIES"
    }
    Write-Host "===================================================================================================="

    return @{ "Iteration" = $Iteration; "DriftCounter" = $DriftCounter; "DriftSummary" = $DriftSummary }
}