function Get-MarketplaceRestrictionPolicy {
    param (
        [string]$AccessToken,
        [ValidateSet("ALLOW_ALL", "ALLOW_LISTED_APPS", "ALLOW_NONE")]
        [string]$DesiredConfiguration
    )
    
    # Call the helper function to Compile current state and evaluate drift from the desired configuration
    Write-Host "Compiling current state and Calculating Drift" 
    $DriftSummary = @()
    $DriftCounter = 0
    $CurrentState = @()
    $Iteration = 0
    
    $PolicyConfigurationName = "Marketplace App Restriction Policy"
    $PreResults = Get-ConfigurationDriftStatus -ConfigurationName $PolicyConfigurationName -DriftCheckLogic {
      
      # Retrieve all two_step* values
      $splat = @{
        Method = "GET"
        Uri = "https://cloudidentity.googleapis.com/v1/policies?pageSize=100&filter=setting.type==('settings/workspace_marketplace.apps_access_options')"
        Headers = @{Authorization = "Bearer $accesstoken"}
      }
      
      $Response = Invoke-WebRequest @splat
      $json = $Response.Content | ConvertFrom-Json
      $adminPolicies = $json.policies | Where {$_.type -eq "ADMIN"}
      if ($adminPolicies.setting) {
        $Settings = $adminPolicies.setting
      } else {
        Write-Error "No Marketplace App Restriction Policy setting found, implying it has not been configured!"
        exit 1
      }

      ## Get indentation for output alignment
      $maxLength = ($PolicyConfigurationName | Measure-Object -Maximum -Property Length).Maximum
      $paddedSettingName = $PolicyConfigurationName.PadRight($maxLength + 1)

      ## Compare values
      $CurrentValue = $Settings.value.accessLevel
      if ($DesiredConfiguration -ne $CurrentValue) {
        $DriftCounter += 1
        $DriftSummary += "$($paddedSettingName): CURRENT: $($CurrentValue) -> DESIRED: $($DesiredConfiguration)"
      }
      $CurrentState += "$($paddedSettingName): $CurrentValue"

      return @{
          "DriftCounter" = $DriftCounter
          "DriftSummary" = $DriftSummary
          "CurrentState" = $CurrentState
      }
    }
    
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