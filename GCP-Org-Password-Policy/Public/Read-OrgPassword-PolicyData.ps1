# # Get-GCPPasswordPolicies.ps1

# param(
#     [Parameter(Mandatory=$true)]
#     [string]$ServiceAccountEmail,
    
#     [Parameter(Mandatory=$true)]
#     [string]$AdminEmail,
    
#     [Parameter(Mandatory=$true)]
#     [string]$P12CertificatePath
# )

# $Scopes = @(
#     "https://www.googleapis.com/auth/cloud-identity",
#     "https://www.googleapis.com/auth/cloud-platform"
# )
# $P12CertificatePassword = 'notasecret'

# try {
#     # Verify P12 file exists
#     if (-not (Test-Path $P12CertificatePath)) {
#         throw "P12 certificate file not found at: $P12CertificatePath"
#     }

#     Write-Host "Reading P12 certificate..."
#     $P12CertificateBase64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($P12CertificatePath))
#     Write-Host "P12 certificate read successfully"

#     Write-Host "Requesting access token..."
#     Write-Host "Service Account: $ServiceAccountEmail"
#     Write-Host "Admin Email: $AdminEmail"
#     Write-Host "Scopes: $($Scopes -join ', ')"

#     $accessTokenParams = @{
#         Issuer = $ServiceAccountEmail
#         Subject = $AdminEmail
#         Scopes = $Scopes
#         P12CertificateBase64 = $P12CertificateBase64
#         P12CertificatePassword = $P12CertificatePassword
#     }

#     $accesstoken = Get-EciGwsAccessToken @accessTokenParams

#     if (-not $accesstoken) {
#         throw "Access token is null or empty"
#     }

#     Write-Host "Access token obtained successfully"

#     $apiParams = @{
#         Method = "GET"
#         Uri = "https://cloudidentity.googleapis.com/v1/policies?pageSize=100&filter=setting.type=='settings/security.password'"
#         Headers = @{
#             Authorization = "Bearer $accesstoken"
#             'Content-Type' = 'application/json'
#         }
#         ErrorAction = 'Stop'
#     }

#     Write-Host "Making API request..."
#     $Response = Invoke-WebRequest @apiParams
#     $policies = $Response.Content | ConvertFrom-Json

#     Write-Output $policies
# }
# catch {
#     Write-Error "An error occurred: $_"
    
#     if ($_.Exception.Response) {
#         $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
#         $reader.BaseStream.Position = 0
#         $reader.DiscardBufferedData()
#         $responseBody = $reader.ReadToEnd()
#         Write-Host "Full error response: $responseBody" -ForegroundColor Red
#     }
    
#     Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
# }