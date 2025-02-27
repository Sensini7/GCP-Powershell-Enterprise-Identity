function Compare-OrgPasswordPolicy {
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

    # Calculate drift for each policy
    foreach ($policy in $passwordPolicies) {
        $settings = $policy.setting.value

        # Compare Password Strength (Map Boolean to STRONG/WEAK)
        $desiredStrength = if ($DesiredPasswordStrengthEnforced) { 'STRONG' } else { 'WEAK' }
        if ($settings.allowedStrength -ne $desiredStrength) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Password Strength: CURRENT: $($settings.allowedStrength) -> DESIRED: $desiredStrength"
        }

        # Compare Minimum Length
        if ($settings.minimumLength -ne $DesiredMinLength) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Minimum Length: CURRENT: $($settings.minimumLength) -> DESIRED: $DesiredMinLength"
        }

        # Compare Maximum Length
        if ($settings.maximumLength -ne $DesiredMaxLength) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Maximum Length: CURRENT: $($settings.maximumLength) -> DESIRED: $DesiredMaxLength"
        }

        # Compare Enforce at Login (True/False comparison)
        if ($settings.enforceRequirementsAtLogin -ne $DesiredEnforceNextSignIn) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Enforce at Login: CURRENT: $($settings.enforceRequirementsAtLogin) -> DESIRED: $DesiredEnforceNextSignIn"
        }

        # Compare Password Reuse (True/False comparison)
        if ($settings.allowReuse -ne $DesiredPasswordReuseAllowed) {
            $DriftCounter++
            $DriftSummary += "Policy $($policy.name) - Password Reuse: CURRENT: $($settings.allowReuse) -> DESIRED: $DesiredPasswordReuseAllowed"
        }

        # Convert expirationDuration from "Xs" format to days
        $currentExpirationDays = if ($settings.expirationDuration -eq '0s') { 0 } else {
            [int]($settings.expirationDuration -replace 's$', '') / 86400
        }

        # Compare Password Expiration Days
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

    # if ($DriftSummary.Count -gt 0) {
    # # Group drift entries by policy
    # $policyDrifts = @{}
    
    # foreach ($drift in $DriftSummary) {
    #     # Extract policy name from drift message
    #     $policyName = ($drift -split ' - ')[0].Replace('Policy ', '')
        
    #     # Get the corresponding policy object for additional details
    #     $policy = $passwordPolicies | Where-Object { $_.name -eq $policyName }
        
    #     if (-not $policyDrifts.ContainsKey($policyName)) {
    #         $policyDrifts[$policyName] = @{
    #             'PolicyDetails' = @{
    #                 'OrgUnit' = $policy.policyQuery.orgUnit
    #                 'AppliesTo' = $policy.policyQuery.query
    #             }
    #             'Drifts' = @()
    #         }
    #     }
        
    #     # Add drift detail (everything after "Policy policyname - ")
    #     $driftDetail = ($drift -split ' - ', 2)[1]
    #     $policyDrifts[$policyName]['Drifts'] += $driftDetail
    # }
    
    # # Display grouped drifts
    # foreach ($policyName in $policyDrifts.Keys) {
    #     Write-Host "`nPolicy: $policyName"
    #     Write-Host "Organization Unit: $($policyDrifts[$policyName]['PolicyDetails']['OrgUnit'])"
    #     Write-Host "Applies to: $($policyDrifts[$policyName]['PolicyDetails']['AppliesTo'])"
    #     Write-Host "`nDrifts detected:"
    #     foreach ($drift in $policyDrifts[$policyName]['Drifts']) {
    #         Write-Host "  - $drift"
    #     }
    #     Write-Host "-----------------------------------"
    # }
    # } else {
    # Write-Host "No drift detected. All password policies match desired state."
    # }

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