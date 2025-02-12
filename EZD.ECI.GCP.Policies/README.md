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

### Private Functions

#### Compare-SuperAdminRecoveryPolicy
Internal function that compares current Super Admin Recovery policy against desired state.

#### Compare-TakeoutPolicy
Internal function that compares current Takeout policies against desired state.

## Example Usage

```powershell
# Check Super Admin Recovery Policy
Get-SuperAdminRecoveryPolicy -SuperAdminRecoveryEnabled $true -AccessToken "your-token"

# Check Takeout Policies
Get-TakeoutPolicy -UserTakeoutEnabled $false -ServicesTakeoutEnabled $false -AccessToken "your-token"
```

## Requirements

- PowerShell 5.1 or higher
- GCP access token with appropriate permissions
- Module: EZD.ECI.GCP.Common

## Exit Codes

- 0: Success - No drift detected
- 2: Drift detected
