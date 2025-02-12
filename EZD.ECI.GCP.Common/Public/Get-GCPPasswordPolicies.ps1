# Get-GCPPasswordPolicies.ps1

# Hardcoded parameters
$ServiceAccountEmail = "github-sp@mindful-life-450521-e0.iam.gserviceaccount.com"
$AdminEmail = "peleke@kemkos.com"
$P12CertificatePath = "C:\Users\Personal\Downloads\mindful-life-450521-e0-c5c74fa10e5c.p12"

$Scopes = @(
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/cloud-identity",
    "https://www.googleapis.com/auth/cloud-identity.policies",
    "https://www.googleapis.com/auth/cloud-identity.policies.readonly"
)

$P12CertificatePassword = 'notasecret'

try {
    Write-Host "Starting password policy check..."
    
    if (-not (Test-Path $P12CertificatePath)) {
        throw "P12 certificate file not found at: $P12CertificatePath"
    }

    $P12CertificateBytes = [System.IO.File]::ReadAllBytes($P12CertificatePath)
    $P12CertificateBase64 = [System.Convert]::ToBase64String($P12CertificateBytes)
    
    $accessTokenParams = @{
        Issuer = $ServiceAccountEmail
        Subject = $AdminEmail
        Scopes = $Scopes
        P12CertificateBase64 = $P12CertificateBase64
        P12CertificatePassword = $P12CertificatePassword
    }

    $accesstoken = Get-EciGwsAccessToken @accessTokenParams

    if (-not $accesstoken) {
        throw "Access token returned null or empty"
    }

    $endpoint = "https://cloudidentity.googleapis.com/v1/policies"
    
    $apiParams = @{
        Method = "GET"
        Uri = $endpoint
        Headers = @{
            Authorization = "Bearer $accesstoken"
            'Content-Type' = 'application/json'
            'Accept' = 'application/json'
        }
        TimeoutSec = 30
        ErrorAction = 'Stop'
    }

    $Response = Invoke-RestMethod @apiParams
    
    # Filter only password policies
    $passwordPolicies = $Response.policies | Where-Object { 
        $_.setting.type -eq 'settings/security.password'
    }

    Write-Host "`nFound $($passwordPolicies.Count) password policies"
    
    foreach ($policy in $passwordPolicies) {
        Write-Host "`nPassword Policy Details:"
        Write-Host "========================="
        Write-Host "Policy ID: $($policy.name)"
        Write-Host "Organization Unit: $($policy.policyQuery.orgUnit)"
        Write-Host "Type: $($policy.type)"
        
        $settings = $policy.setting.value
        Write-Host "`nPassword Requirements:"
        Write-Host "Password Strength: $($settings.allowedStrength)"
        Write-Host "Minimum Length: $($settings.minimumLength) characters"
        Write-Host "Maximum Length: $($settings.maximumLength) characters"
        Write-Host "Enforce at Login: $($settings.enforceRequirementsAtLogin)"
        Write-Host "Allow Password Reuse: $($settings.allowReuse)"
        Write-Host "Password Expiration: $(if ($settings.expirationDuration -eq '0s') { 'Never' } else { $settings.expirationDuration })"
        
        Write-Host "`nApplies to: $($policy.policyQuery.query)"
        Write-Host "-------------------------"
    }

    return $passwordPolicies
}
catch {
    Write-Error "An error occurred: $_"
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        Write-Host "Status Code: $statusCode"
        Write-Host "Status Description: $statusDescription"
    }
}