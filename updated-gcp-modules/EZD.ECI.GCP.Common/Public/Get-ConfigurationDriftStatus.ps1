function Get-ConfigurationDriftStatus {
    param (
        [Parameter(Mandatory=$true)]
        [scriptblock]$DriftCheckLogic,
        [Parameter(Mandatory=$true)]
        [string]$ConfigurationName
    )

    $DriftSummary = @()
    $DriftCounter = 0
    $Iteration = 0

    # Execute the provided drift check logic
    $result = & $DriftCheckLogic
    $DriftCounter = $result.DriftCounter
    $DriftSummary = $result.DriftSummary
    $CurrentState = $result.CurrentState

    # Display results
    Write-Host "===================================================================================================="
    if ($DriftCounter -eq 0) {
        Write-Host "No drift detected. The current state aligns with the desired state."
    } else {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state"
        Write-Host "DRIFT SUMMARY:"
        $DriftSummary | ForEach-Object { Write-Host $_ }
    }

    Write-Host "====================================================================================================" 
    Write-Host "------------------- CURRENT STATE OF $($ConfigurationName.ToUpper()) --------------------"
    Write-Host "===================================================================================================="

    $CurrentState | ForEach-Object { Write-Host $_ }

    $Iteration += 1

    Write-Host "===================================================================================================="
    if ($DriftCounter -eq 0) {
        Write-Host "No drift detected. The current state aligns with the desired state."
    } else {
        Write-Host "DRIFT DETECTED: The current state does not align with the desired state"
    }
    Write-Host "===================================================================================================="

    return @{
        "Iteration" = $Iteration
        "DriftCounter" = $DriftCounter
        "DriftSummary" = $DriftSummary
    }
}
