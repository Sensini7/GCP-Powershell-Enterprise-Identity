# Get-APIControlAuditLogs.ps1

# Hardcoded parameters
$ServiceAccountEmail = "github-sp@mindful-life-450521-e0.iam.gserviceaccount.com"
$AdminEmail = "peleke@kemkos.com"
$P12CertificatePath = "C:\Users\Personal\Downloads\mindful-life-450521-e0-c5c74fa10e5c.p12"

# Define fixed output path
$OutputFolder = "EZD.ECI.GCP.API.Controls.Settings"
$OutputFile = "API_Controls_Audit_Log.csv"
$OutputPath = Join-Path $OutputFolder $OutputFile

$Scopes = @(
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/cloud-identity",
    "https://www.googleapis.com/auth/admin.reports.audit.readonly",
    "https://www.googleapis.com/auth/admin.reports.usage.readonly"
)

$P12CertificatePassword = 'notasecret'

function Get-APIControlAuditLogs {
    try {
        # Create output directory if it doesn't exist
        if (-not (Test-Path $OutputFolder)) {
            New-Item -ItemType Directory -Path $OutputFolder | Out-Null
            Write-Host "Created output directory: $OutputFolder"
        }

        # Authentication setup remains the same...
        if (-not (Test-Path $P12CertificatePath)) {
            throw "P12 certificate file not found at: $P12CertificatePath"
        }

        Write-Host "Reading P12 certificate..."
        $P12CertificateBase64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($P12CertificatePath))
        Write-Host "P12 certificate read successfully"

        Write-Host "Requesting access token..."
        $accessTokenParams = @{
            Issuer = $ServiceAccountEmail
            Subject = $AdminEmail
            Scopes = $Scopes
            P12CertificateBase64 = $P12CertificateBase64
            P12CertificatePassword = $P12CertificatePassword
        }

        $accesstoken = Get-EciGwsAccessToken @accessTokenParams

        if (-not $accesstoken) {
            throw "Access token is null or empty"
        }

        Write-Host "Access token obtained successfully"

        # Define the event names we want to check
        $eventNames = @(
            "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS",
            "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS",
            "BLOCK_ALL_THIRD_PARTY_API_ACCESS",
            "TRUST_DOMAIN_OWNED_OAUTH2_APPS",
            "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS"
        )

        $allEvents = @()

        foreach ($eventName in $eventNames) {
            $baseUrl = "https://admin.googleapis.com/admin/reports/v1/activity/users/all/applications/admin"
            $queryParams = @(
                "maxResults=1000",
                "eventName=$eventName",
                "startTime=2025-01-01T00:00:00Z"  # Adding start time to get recent events
            )

            $apiUrl = "$baseUrl`?$($queryParams -join '&')"

            $apiParams = @{
                Method = "GET"
                Uri = $apiUrl
                Headers = @{
                    Authorization = "Bearer $accesstoken"
                    'Content-Type' = 'application/json'
                }
                ErrorAction = 'SilentlyContinue'
            }

            Write-Host "Making API request for $eventName..."
            Write-Host "API URL: $apiUrl" -ForegroundColor Yellow
            
            try {
                $Response = Invoke-RestMethod @apiParams
                if ($Response.items) {
                    $allEvents += $Response.items
                }
            }
            catch {
                Write-Host "No events found for $eventName" -ForegroundColor Yellow
                continue
            }
        }

        Write-Host "`nProcessing events..."
        Write-Host "Total events found: $($allEvents.Count)" -ForegroundColor Yellow

        $formattedLogs = @()
        
        foreach ($event in $allEvents) {
            $eventType = $event.events[0].name
            $orgUnit = ($event.events[0].parameters | Where-Object { $_.name -eq "ORG_UNIT_NAME" }).value

            $formattedLog = [PSCustomObject]@{
                Date = ([DateTime]$event.id.time).ToString("yyyy-MM-ddTHH:mm:ssK")
                Event = switch ($eventType) {
                    "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS" { "All third party API access unblocked" }
                    "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS" { "Allow Google Sign-in only third party API access" }
                    "BLOCK_ALL_THIRD_PARTY_API_ACCESS" { "All third party API access blocked" }
                    "TRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Domain Owned Apps Trusted" }
                    "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Domain Owned Apps Not Trusted" }
                }
                Description = switch ($eventType) {
                    "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS" { "All third party API Access unblocked (org_unit_name: {$orgUnit})" }
                    "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS" { "Allow Google Sign-in only third party API access (org_unit_name: {$orgUnit})" }
                    "BLOCK_ALL_THIRD_PARTY_API_ACCESS" { "All access to third-party apps blocked (org_unit_name: {$orgUnit})" }
                    "TRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Domain Owned Apps added to trusted list (org_unit_name: {$orgUnit})" }
                    "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Domain Owned Apps removed from trusted list (org_unit_name: {$orgUnit})" }
                }
                Actor = $event.actor.email
                'IP address' = $event.ipAddress
            }
            $formattedLogs += $formattedLog
        }
        
        if ($formattedLogs.Count -eq 0) {
            Write-Host "`nNo matching events found."
        } else {
            $formattedLogs = $formattedLogs | Sort-Object Date -Descending
            
            # Export to fixed location, overwriting existing file
            $formattedLogs | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -Force
            
            Write-Host "`nFound $($formattedLogs.Count) matching events:" -ForegroundColor Green
            foreach ($log in $formattedLogs) {
                Write-Host "`n----------------------------------------"
                Write-Host "Date: $($log.Date)" -ForegroundColor Yellow
                Write-Host "Event: $($log.Event)" -ForegroundColor Cyan
                Write-Host "Description: $($log.Description)" -ForegroundColor White
                Write-Host "Actor: $($log.Actor)" -ForegroundColor Green
                Write-Host "IP Address: $($log.'IP address')" -ForegroundColor Gray
                Write-Host "----------------------------------------"
            }
        }

        Write-Host "`nReport exported to: $OutputPath"
        return $formattedLogs

    } catch {
        Write-Error "An error occurred: $_"
        if ($_.ErrorDetails.Message) {
            Write-Host "Error Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }
}

# Execute the function
Get-APIControlAuditLogs