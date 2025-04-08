# EZD.ECI.GCP.Policies

This module contains functions for managing Google Cloud Platform policies related to security and compliance.

## Overview

The `EZD.ECI.GCP.Policies` module provides PowerShell functions to manage Google Cloud Identity policies. It enables drift detection and enforcement of security configurations, focusing on Super Admin Recovery and Takeout policies.

## Functions

### Public Functions

#### Get-SuperAdminRecoveryPolicy
Detects drift in Super Admin Recovery policy settings.

Parameters:
- `SuperAdminRecoveryEnabled` [bool] - Desired state for Super Admin Recovery
- `AccessToken` [string] - GCP authentication token

Returns:
- ExitCode 0: No drift detected
- ExitCode 2: Drift detected

#### Get-TakeoutPolicy
Detects drift in Takeout policy settings.

Parameters:
- `UserTakeoutEnabled` [bool] - Desired state for User Takeout
- `ServicesTakeoutEnabled` [bool] - Desired state for Services Takeout
- `AccessToken` [string] - GCP authentication token

Returns:
- ExitCode 0: No drift detected
- ExitCode 2: Drift detected

#### Get-2StepVerificationSettings
Detects drift in 2-Step Verification settings.

Parameters:
- `AccessToken` [string] - GCP authentication token
- `Enrollment` [string] - Desired state for enrollment, allow users to turn on 2-Step Verification
- `EnforcementFrom` [string] - Desired enforcement start date
- `DeviceTrust` [string] - Desired state for allowing the user to trust the device 
- `EnforcementFactor` [string] - Desired state for allowed 2-Step Verification methods
- `GracePeriod` [string] - Desired new user enrollment grace period
- `BackupCodeExceptionPeriod` [string] - Desired backup code exception period

Returns:
- ExitCode 0: No drift detected
- ExitCode 2: Drift detected

### Private Functions

#### Compare-SuperAdminRecoveryPolicy
Internal function that compares current Super Admin Recovery policy against desired state.

#### Compare-TakeoutPolicy
Internal function that compares current Takeout policies against desired state.

## Example Usage

```powershell
# Auth using `EZD.ECI.GCP.Common` (or build JWT yourself)

$accesstoken = Get-EciGwsAccessToken

# Check Super Admin Recovery Policy
Get-SuperAdminRecoveryPolicy -SuperAdminRecoveryEnabled $true -AccessToken $accesstoken

# Check Takeout Policies
Get-TakeoutPolicy -UserTakeoutEnabled $false -ServicesTakeoutEnabled $false -AccessToken $accesstoken

# Check 2-Step Verification Settings
Get-2StepVerificationSettings -AccessToken $accesstoken -Enrollment $true -DeviceTrust $true -EnforcementFactor "ALL" -EnforcementFrom "03/01/2050 05:00:00" -GracePeriod "604800s" -BackupCodeExceptionPeriod "86400s"

# Check Marketplace Restriction Policy
Get-MarketplaceRestrictionPolicy -AccessToken $accesstoken -DesiredConfiguration "ALLOW_LISTED_APPS"
```

## Requirements

- PowerShell 5.1 or higher
- GCP access token with appropriate permissions
- Module: EZD.ECI.GCP.Common

## Exit Codes

- 0: Success - No drift detected
- 2: Drift detected

