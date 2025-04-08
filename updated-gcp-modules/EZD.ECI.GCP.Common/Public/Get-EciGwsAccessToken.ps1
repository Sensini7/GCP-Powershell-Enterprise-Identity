function Get-EciGwsAccessToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Issuer,

        [Parameter()]
        [string]
        $Subject,

        [Parameter()]
        [string[]]$Scopes,

        [Parameter()]
        [string]
        $P12CertificateBase64,

        [Parameter()]
        [string]
        $P12CertificatePassword
    )
    
    # Define the token endpoint URL
    $TokenEndpoint = 'https://www.googleapis.com/oauth2/v4/token'
    try {
        ## Build JWT
        ## See https://developers.google.com/identity/protocols/oauth2/service-account#httprest
        
        # Get the current time in seconds since Unix epoch
        $now = [math]::Round(((Get-Date).ToUniversalTime() - ([datetime]"1970-01-01T00:00:00Z").ToUniversalTime()).TotalSeconds)
        
        # Create JWT header
        $jwtHeader = @{
            alg = 'RS256'
            typ = 'JWT'
        } | ConvertTo-Json
        $jwtBase64Header = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($jwtHeader))

        # Create JWT payload
        $jwtPayload = [Ordered]@{
            iss   = $Issuer
            sub   = $Subject
            scope = $($Scopes -join " ")
            aud   = $TokenEndpoint
            exp   = $now + 3600
            iat   = $now
        } | ConvertTo-Json
        $jwtBase64Payload = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($jwtPayload))

        # Decode the base64 encoded P12 certificate
        $rawP12Certificate = [system.convert]::FromBase64String($P12CertificateBase64)
        $p12Certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($rawP12Certificate, $P12CertificatePassword, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
        
        # Extract the private key from the certificate
        $rsaPrivate = $P12Certificate.PrivateKey
        $rsa = [System.Security.Cryptography.RSACryptoServiceProvider]::new()
        $rsa.ImportParameters($rsaPrivate.ExportParameters($true))
        
        # Create the signature input
        $signatureInput = "$jwtBase64Header.$jwtBase64Payload"
        
        # Sign the data
        $signature = $rsa.SignData([Text.Encoding]::UTF8.GetBytes($signatureInput), "SHA256")
        $base64Signature = [System.Convert]::ToBase64String($signature)
        
        # Create the JWT token
        $jwtToken = "$signatureInput.$base64Signature"

        # Prepare the parameters for the REST API call
        $splatParams = @{
            Uri         = $TokenEndpoint
            Method      = 'POST'
            Body        = @{
                grant_type = 'urn:ietf:params:oauth:grant-type:jwt-bearer'
                assertion  = $jwtToken
            }
            ContentType = 'application/x-www-form-urlencoded'
        }
        
        # Make the REST API call to get the access token
        $response = Invoke-RestMethod @splatParams
        $response.access_token
    }
    catch {
        # Handle any errors that occur during the process
        $PSCmdlet.ThrowTerminatingError($_)
    }
}