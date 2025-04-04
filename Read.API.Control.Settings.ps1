# Get-APIControlAuditLogs.ps1

# Hardcoded parameters
$ServiceAccountEmail = "github-sp@mindful-life-450521-e0.iam.gserviceaccount.com"
$AdminEmail = "peleke@kemkos.com"
$P12CertificatePath = "C:\Users\Personal\Downloads\mindful-life-450521-e0-c5c74fa10e5c.p12"

# Define fixed output paths
$OutputFolder = "EZD.ECI.GCP.API.Controls.Settings"
$OutputFile = "API_Controls_Audit_Log.csv"
$CurrentStateFile = "Current_API_Controls_State.csv"
$OutputPath = Join-Path $OutputFolder $OutputFile
$CurrentStatePath = Join-Path $OutputFolder $CurrentStateFile

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

        # Authentication setup
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
                "startTime=2025-01-01T00:00:00Z"
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
                OrgUnit = $orgUnit
                Setting = switch ($eventType) {
                    { $_ -match "THIRD_PARTY_API_ACCESS" } { "Third Party API Access" }
                    { $_ -match "DOMAIN_OWNED_OAUTH2_APPS" } { "Domain Owned Apps Trust" }
                }
                Event = switch ($eventType) {
                    "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS" { "All third party API access unblocked" }
                    "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS" { "Allow Google Sign-in only third party API access" }
                    "BLOCK_ALL_THIRD_PARTY_API_ACCESS" { "All third party API access blocked" }
                    "TRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Domain Owned Apps Trusted" }
                    "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Domain Owned Apps Not Trusted" }
                }
                Status = switch ($eventType) {
                    "UNBLOCK_ALL_THIRD_PARTY_API_ACCESS" { "Unrestricted" }
                    "SIGN_IN_ONLY_THIRD_PARTY_API_ACCESS" { "Sign-in Only" }
                    "BLOCK_ALL_THIRD_PARTY_API_ACCESS" { "Blocked" }
                    "TRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Trusted" }
                    "UNTRUST_DOMAIN_OWNED_OAUTH2_APPS" { "Not Trusted" }
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
            
            # Export full audit log
            $formattedLogs | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8 -Force
            
            # Get current state for each setting and org unit
            $currentState = $formattedLogs | 
                Group-Object OrgUnit, Setting | 
                ForEach-Object {
                    $_.Group | Select-Object -First 1
                } | 
                Select-Object Date, OrgUnit, Setting, Status, Actor, 'IP address' |
                Sort-Object OrgUnit, Setting

            # Export current state
            $currentState | Export-Csv -Path $CurrentStatePath -NoTypeInformation -Encoding UTF8 -Force
            
            Write-Host "`nCurrent State of Settings:" -ForegroundColor Green
            Write-Host "----------------------------------------" -ForegroundColor Gray
            
            # Headers
            $headers = "Date                 | Organization Unit | Setting                 | Status       | Changed By          | IP Address"
            $separator = "--------------------|------------------|------------------------|-------------|--------------------|-----------------"
            Write-Host $headers -ForegroundColor Cyan
            Write-Host $separator -ForegroundColor Gray

            # Display current state with color coding
            foreach ($state in $currentState) {
                # Status color coding
                $statusColor = switch ($state.Status) {
                    "Not Trusted" { "Red" }
                    "Unrestricted" { "Yellow" }
                    "Blocked" { "Green" }
                    "Trusted" { "Green" }
                    "Sign-in Only" { "Yellow" }
                    default { "White" }
                }

                # Format each field with fixed width
                $date = $state.Date.PadRight(20)
                $orgUnit = $state.OrgUnit.PadRight(18)
                $setting = $state.Setting.PadRight(24)
                $status = $state.Status.PadRight(13)
                $actor = $state.Actor.PadRight(20)
                $ip = $state.'IP address'

                # Build the line
                Write-Host "$date" -NoNewline
                Write-Host "| " -NoNewline -ForegroundColor Gray
                Write-Host "$orgUnit" -NoNewline
                Write-Host "| " -NoNewline -ForegroundColor Gray
                Write-Host "$setting" -NoNewline
                Write-Host "| " -NoNewline -ForegroundColor Gray
                Write-Host "$status" -NoNewline -ForegroundColor $statusColor
                Write-Host "| " -NoNewline -ForegroundColor Gray
                Write-Host "$actor" -NoNewline
                Write-Host "| " -NoNewline -ForegroundColor Gray
                Write-Host "$ip"
            }
            Write-Host "----------------------------------------" -ForegroundColor Gray

            # Add summary section
            Write-Host "`nSummary:" -ForegroundColor Green
            Write-Host "----------------------------------------" -ForegroundColor Gray
            
            # Count total changes
            $totalChanges = $formattedLogs.Count
            $uniqueActors = ($formattedLogs.Actor | Select-Object -Unique).Count
            $lastChange = $formattedLogs | Select-Object -First 1
            
            Write-Host "Total changes made: " -NoNewline
            Write-Host $totalChanges -ForegroundColor Yellow
            Write-Host "Unique users making changes: " -NoNewline
            Write-Host $uniqueActors -ForegroundColor Yellow
            Write-Host "Last change made: " -NoNewline
            Write-Host "$($lastChange.Date) by $($lastChange.Actor)" -ForegroundColor Yellow

            # Security Status
            Write-Host "`nSecurity Status:" -ForegroundColor Green
            Write-Host "----------------------------------------" -ForegroundColor Gray
            
            foreach ($state in $currentState) {
                $statusIcon = switch ($state.Status) {
                    "Not Trusted" { "✅" }
                    "Unrestricted" { "⚠️" }
                    "Blocked" { "✅" }
                    "Trusted" { "⚠️" }
                    "Sign-in Only" { "⚠️" }
                    default { "❓" }
                }
                
                $statusColor = switch ($state.Status) {
                    "Not Trusted" { "Red" }
                    "Unrestricted" { "Yellow" }
                    "Blocked" { "Green" }
                    "Trusted" { "Green" }
                    "Sign-in Only" { "Yellow" }
                    default { "White" }
                }

                Write-Host "$statusIcon $($state.Setting) is " -NoNewline
                Write-Host $state.Status -ForegroundColor $statusColor -NoNewline
                Write-Host " for $($state.OrgUnit)"
            }

            Write-Host "`nFull audit log exported to: " -NoNewline
            Write-Host $OutputPath -ForegroundColor Cyan
            Write-Host "Current state exported to: " -NoNewline
            Write-Host $CurrentStatePath -ForegroundColor Cyan
        }

        return @{
            FullAuditLog = $formattedLogs
            CurrentState = $currentState
        }

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