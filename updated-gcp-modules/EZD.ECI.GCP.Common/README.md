# Module: Common

**Required Permissions**: None

**Required PowerShell Modules**: None.

## Public Functions

### Function: Get-EciGwsAccessToken

**Description**: Builds a JWT from the provided parameters and retrieves an access token. Intended for usage with a Service Account via a p12 key that is base64 encoded. See https://developers.google.com/identity/protocols/oauth2/service-account#httprest

**Input Variables**: 
 - `Issuer`: The email of the service account to be used.
 - `Subject`: The admin user for the service account to obtain delegated access to the domain.
 - `Scopes`: OAuth scopes to be requested. For a full list, see https://developers.google.com/identity/protocols/oauth2/scopes.
 - `P12CertificateBase64`: The base64 encoded .p12 certificate for the service account.
 - `P12CertificatePassword`: The password of the base64 encoded .p12 certificate for the service account.

**Example Usage**:
```powershell
$issuer = "service-account@example.com"
$subject = "admin@example.com"
$scopes = @("https://www.googleapis.com/auth/cloud-platform")
$p12CertBase64 = "base64-encoded-p12-certificate"
$p12CertPassword = "certificate-password"

$accessToken = Get-EciGwsAccessToken -Issuer $issuer -Subject $subject -Scopes $scopes -P12CertificateBase64 $p12CertBase64 -P12CertificatePassword $p12CertPassword
Write-Output $accessToken
```