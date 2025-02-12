function Get-SuperAdminRecoveryPolicy {
    param (
        [bool]$SuperAdminRecoveryEnabled,
        [string]$AccessToken
    )
    
    # Call the helper function to Compile current state and evaluate drift from the desired configuration
    Write-Host "Compiling current state and Calculating Drift" 
    $Iteration = 0
    $PreResults = Compare-SuperAdminRecoveryPolicy
    $Iteration = $PreResults["Iteration"]
    $DriftCounter = $PreResults["DriftCounter"]
    $DriftSummary = $PreResults["DriftSummary"]

    Write-Host "THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE"
    if ($DriftCounter -gt 0) {
        return Get-ReturnValue -ExitCode 2 -DriftSummary $DriftSummary
    } else {
        return Get-ReturnValue -ExitCode 0 -DriftSummary $DriftSummary
    }
}