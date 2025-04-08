## See "2-Step Verification" in https://cloud.google.com/identity/docs/concepts/supported-policy-api-settings
function Get-2StepVerificationSettings {
    param (
        [string]$AccessToken,
        $Enrollment,
        $DeviceTrust,
        $EnforcementFactor,
        $EnforcementFrom,
        $GracePeriod,
        $BackupCodeExceptionPeriod
    )
    
    # Call the helper function to Compile current state and evaluate drift from the desired configuration
    Write-Host "Compiling current state and Calculating Drift" 
    $DriftSummary = @()
    $DriftCounter = 0
    $CurrentState = @()
    $Iteration = 0
    $PreResults = Get-ConfigurationDriftStatus -ConfigurationName "2-Step Verification Settings" -DriftCheckLogic {
      $ApiDict = @{
        "settings/security.two_step_verification_enrollment" = $Enrollment
        "settings/security.two_step_verification_device_trust" = $DeviceTrust
        "settings/security.two_step_verification_enforcement_factor" = $EnforcementFactor
        "settings/security.two_step_verification_enforcement" = $EnforcementFrom
        "settings/security.two_step_verification_grace_period" = $GracePeriod
        "settings/security.two_step_verification_sign_in_code" = $BackupCodeExceptionPeriod
      }

      $FriendlyNames = @{
        "settings/security.two_step_verification_enrollment" = "Two-Step Verification Enrollment"
        "settings/security.two_step_verification_device_trust" = "Two-Step Verification Device Trust"
        "settings/security.two_step_verification_enforcement_factor" = "Two-Step Verification Enforcement Factor"
        "settings/security.two_step_verification_enforcement" = "Two-Step Verification Enforcement"
        "settings/security.two_step_verification_grace_period" = "Two-Step Verification Grace Period"
        "settings/security.two_step_verification_sign_in_code" = "Two-Step Verification Backup Code Exception Period"
      }

      # Retrieve all two_step* values
      $splat = @{
        Method = "GET"
        Uri = "https://cloudidentity.googleapis.com/v1/policies?pageSize=100&filter=setting.type.matches('settings/security.two_step.*')"
        Headers = @{Authorization = "Bearer $accesstoken"}
      }
      
      $Response = Invoke-WebRequest @splat
      $json = $Response.Content | ConvertFrom-Json
      $adminPolicies = $json.policies | Where {$_.type -eq "ADMIN"}
      if ($adminPolicies.setting) {
        $Settings = $adminPolicies.setting
      } else {
        Write-Error "No two-step verification settings found, implying it has not been configured!"
        exit 1
      }

      ## Get indentation for output alignment
      $maxLength = ($FriendlyNames.Values | Measure-Object -Maximum -Property Length).Maximum
      
      ## Compare values
      foreach ($setting in $ApiDict.keys) {
        $CurrentValue = ($Settings | Where {$_.type -eq $setting}).value | select-Object -ExpandProperty *
        $DesiredValue = $($ApiDict[$setting])
        
        if ($DesiredValue -ne $CurrentValue) {
          $DriftCounter += 1
          $DriftSummary += "$($FriendlyNames[$setting]): CURRENT: $CurrentValue -> DESIRED: $DesiredValue"
        }
        $paddedSettingName = $FriendlyNames[$setting].PadRight($maxLength+1)
        $CurrentState += "$($paddedSettingName): $CurrentValue"
      }
      

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