function Get-PasswordPolicy {
    param (
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
        [int]$DesiredPasswordExpirationDays,
        [Parameter(Mandatory)]
        [string]$AccessToken
    )
    
    # Hardcoded parameters
    # $ServiceAccountEmail = "github-sp@mindful-life-450521-e0.iam.gserviceaccount.com"
    # $AdminEmail = "peleke@kemkos.com"
    # $P12CertificatePath = "C:\Users\Personal\Downloads\mindful-life-450521-e0-c5c74fa10e5c.p12"

    # $Scopes = @(
    #     "https://www.googleapis.com/auth/cloud-platform",
    #     "https://www.googleapis.com/auth/cloud-identity",
    #     "https://www.googleapis.com/auth/cloud-identity.policies",
    #     "https://www.googleapis.com/auth/cloud-identity.policies.readonly"
    # )

    # $P12CertificatePassword = 'notasecret'

    # try {
    #     Write-Host "Starting password policy check..."
        
    #     if (-not (Test-Path $P12CertificatePath)) {
    #         throw "P12 certificate file not found at: $P12CertificatePath"
    #     }

    #     $P12CertificateBytes = [System.IO.File]::ReadAllBytes($P12CertificatePath)
    #     $P12CertificateBase64 = [System.Convert]::ToBase64String($P12CertificateBytes)
        
    #     $accessTokenParams = @{
    #         Issuer = $ServiceAccountEmail
    #         Subject = $AdminEmail
    #         Scopes = $Scopes
    #         P12CertificateBase64 = $P12CertificateBase64
    #         P12CertificatePassword = $P12CertificatePassword
    #     }

    #     $accesstoken = Get-EciGwsAccessToken @accessTokenParams

    #     if (-not $accesstoken) {
    #         throw "Access token returned null or empty"
    #     }

    #     $endpoint = "https://cloudidentity.googleapis.com/v1/policies"
        
    #     $apiParams = @{
    #         Method = "GET"
    #         Uri = $endpoint
    #         Headers = @{
    #             Authorization = "Bearer $accesstoken"
    #             'Content-Type' = 'application/json'
    #             'Accept' = 'application/json'
    #         }
    #         TimeoutSec = 30
    #         ErrorAction = 'Stop'
    #     }

    #     $Response = Invoke-RestMethod @apiParams
        
    # Call the helper function to Compile current state and evaluate drift
    Write-Host "Compiling current state and Calculating Drift" 
    $Iteration = 0
    $PreResults = Compare-OrgPasswordPolicy 
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $DriftSummary = $PreResults["DriftSummary"]

    Write-Host "THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE"
    if ($DriftCounter -gt 0) {
        return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
    } else {
        return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
    }
    
    catch {
        Write-Error "An error occurred: $_"
        throw
    }
}