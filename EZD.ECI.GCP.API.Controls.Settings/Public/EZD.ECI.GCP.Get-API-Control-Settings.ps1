function Get-APIControlSettings {
    param (
        [Parameter(Mandatory)]
        [bool]$DesiredDomainOwnedAppsTrust,
        [Parameter(Mandatory)]
        [bool]$DesiredBlockThirdPartyAPIAccess,
        [Parameter(Mandatory)]
        [string]$accesstoken
    )
    

    # Call the helper function to Compile current state and evaluate drift
    Write-Host "Compiling current state and Calculating Drift" 
    $Iteration = 0
    $PreResults = Compare-APIControlSettings 
    # -DesiredDomainOwnedAppsTrust $DesiredDomainOwnedAppsTrust `
    #                                        -DesiredBlockThirdPartyAPIAccess $DesiredBlockThirdPartyAPIAccess `
    #                                        -accesstoken $accesstoken
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

# Export-ModuleMember -Function Get-APIControlSettings