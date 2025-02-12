function Compare-OrgPasswordPolicy {
    param(
        [Parameter(Mandatory)]
        [string]$accesstoken,
        [Parameter(Mandatory)]
        [bool]$DesiredPasswordStrengthEnforced,
        [Parameter(Mandatory)]
        [int]$DesiredMinLength,
        [Parameter(Mandatory)]
        [int]$DesiredMaxLength,
        [Parameter(Mandatory)]
        [bool]$DesiredEnforceNextSignIn,
        [Parameter(Mandatory)]
        [bool]$DesiredPasswordReuseAllowed,
        [Parameter(Mandatory)]
        [int]$DesiredPasswordExpirationDays
    )

    # Build API request
    $splat = @{
        Method  = "GET"
        Uri     = "https://cloudidentity.googleapis.com/v1/policies"
        Headers = @{Authorization = "Bearer $accesstoken"}
    }
    
    $Response = Invoke-WebRequest @splat
    $json = $Response.Content | ConvertFrom-Json
    
    # Extract current password policy settings
    $passwordPolicy = ($json.policies | Where-Object { $_.setting.type -eq "settings/password" }).setting.value

    $CurrentStrengthEnforced = $passwordPolicy.passwordStrength
    $CurrentMinLength = $passwordPolicy.minimumLength
    $CurrentMaxLength = $passwordPolicy.maximumLength
    $CurrentEnforceNextSignIn = $passwordPolicy.enforceOnNextSignIn
    $CurrentPasswordReuseAllowed = $passwordPolicy.passwordReuseAllowed
    $CurrentPasswordExpirationDays = $passwordPolicy.passwordExpirationDays

    $DriftSummary = @()
    $DriftCounter = 0

    # Compare each setting and track differences
    if ($DesiredPasswordStrengthEnforced -ne $CurrentStrengthEnforced) {
        $DriftCounter++
        $DriftSummary += "Password Strength Enforcement: CURRENT: $CurrentStrengthEnforced -> DESIRED: $DesiredPasswordStrengthEnforced"
    }

    if ($DesiredMinLength -ne $CurrentMinLength) {
        $DriftCounter++
        $DriftSummary += "Minimum Password Length: CURRENT: $CurrentMinLength -> DESIRED: $DesiredMinLength"
    }

    if ($DesiredMaxLength -ne $CurrentMaxLength) {
        $DriftCounter++
        $DriftSummary += "Maximum Password Length: CURRENT: $CurrentMaxLength -> DESIRED: $DesiredMaxLength"
    }

    if ($DesiredEnforceNextSignIn -ne $CurrentEnforceNextSignIn) {
        $DriftCounter++
        $DriftSummary += "Enforce on Next Sign-in: CURRENT: $CurrentEnforceNextSignIn -> DESIRED: $DesiredEnforceNextSignIn"
    }

    if ($DesiredPasswordReuseAllowed -ne $CurrentPasswordReuseAllowed) {
        $DriftCounter++
        $DriftSummary += "Password Reuse Allowed: CURRENT: $CurrentPasswordReuseAllowed -> DESIRED: $DesiredPasswordReuseAllowed"
    }

    if ($DesiredPasswordExpirationDays -ne $CurrentPasswordExpirationDays) {
        $DriftCounter++
        $DriftSummary += "Password Expiration (Days): CURRENT: $CurrentPasswordExpirationDays -> DESIRED: $DesiredPasswordExpirationDays"
    }

    # Summarize Drift
    Write-Host "===================================================================================================="
    Write-Host "DRIFT SUMMARY:"
    if ($DriftCounter -eq 0) {
        Write-Host "No drift detected. Current password policies match desired state."
    } else {
        $DriftSummary | ForEach-Object { Write-Host $_ }
    }

    # Summarize Current State
    Write-Host "===================================================================================================="
    Write-Host "-------------------------- CURRENT PASSWORD POLICY STATE -------------------------------------------"
    Write-Host "Password Strength Enforced: $CurrentStrengthEnforced"
    Write-Host "Minimum Length: $CurrentMinLength"
    Write-Host "Maximum Length: $CurrentMaxLength"
    Write-Host "Enforce on Next Sign-in: $CurrentEnforceNextSignIn"
    Write-Host "Password Reuse Allowed: $CurrentPasswordReuseAllowed"
    Write-Host "Password Expiration (Days): $CurrentPasswordExpirationDays"
    Write-Host "===================================================================================================="

    return @{
        DriftExists = ($DriftCounter -gt 0)
        DriftCount = $DriftCounter
        DriftSummary = $DriftSummary
        CurrentState = @{
            PasswordStrengthEnforced = $CurrentStrengthEnforced
            MinLength = $CurrentMinLength
            MaxLength = $CurrentMaxLength
            EnforceNextSignIn = $CurrentEnforceNextSignIn
            PasswordReuseAllowed = $CurrentPasswordReuseAllowed
            PasswordExpirationDays = $CurrentPasswordExpirationDays
        }
    }
}