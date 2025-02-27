# GCP-Powershell-Enterprise-Identity

<!-- PS C:\Users\Personal\Desktop\Ovus-jobdesc\GCP-Powershell-Enterprise-Identity> Get-PasswordPolicy
 
cmdlet Get-PasswordPolicy at command pipeline position 1
Supply values for the following parameters:
DesiredPasswordStrengthEnforced: false
DesiredMinLength: 8  
DesiredMaxLength: 100
DesiredEnforceNextSignIn: false
DesiredPasswordReuseAllowed: false
DesiredPasswordExpirationDays: 90
Starting password policy check...
Compiling current state and Calculating Drift
====================================================================================================
DRIFT SUMMARY:
Policy policies/awazjjhiasxmtuoibsjnvrfpuefaq - Password Strength: CURRENT: STRONG -> DESIRED: ENABLED
Policy policies/awazjjhiasxmtuoibsjnvrfpuefaq - Enforce at Login: CURRENT: DISABLED -> DESIRED: ENABLED
Policy policies/awazjjhiasxmtuoibsjnvrfpuefaq - Password Reuse: CURRENT: DISABLED -> DESIRED: ENABLED
Policy policies/awazjjhiasxmtuoibsjnvrfpuefaq - Password Expiration Days: CURRENT: 0 -> DESIRED: 90
Policy policies/awazjjhiasrovqgudcjnvrfpuefaq - Password Strength: CURRENT: STRONG -> DESIRED: ENABLED
Policy policies/awazjjhiasrovqgudcjnvrfpuefaq - Enforce at Login: CURRENT: DISABLED -> DESIRED: ENABLED
Policy policies/awazjjhiasrovqgudcjnvrfpuefaq - Password Reuse: CURRENT: DISABLED -> DESIRED: ENABLED
Policy policies/awazjjhiasrovqgudcjnvrfpuefaq - Password Expiration Days: CURRENT: 0 -> DESIRED: 90
Policy policies/agazjjhiataz7hv7eojnvrfpuefaq - Password Strength: CURRENT: WEAK -> DESIRED: ENABLED
Policy policies/agazjjhiataz7hv7eojnvrfpuefaq - Enforce at Login: CURRENT: DISABLED -> DESIRED: ENABLED
Policy policies/agazjjhiataz7hv7eojnvrfpuefaq - Password Reuse: CURRENT: DISABLED -> DESIRED: ENABLED
Policy policies/agazjjhiataz7hv7eojnvrfpuefaq - Password Expiration Days: CURRENT: 0 -> DESIRED: 90
====================================================================================================
------------------- CURRENT STATE OF PASSWORD POLICIES --------------------
====================================================================================================

Policy: policies/awazjjhiasxmtuoibsjnvrfpuefaq
Organization Unit: orgUnits/03ph8a2z45ooh4i
Applies to: entity.org_units.exists(org_unit, org_unit.org_unit_id == orgUnitId('03ph8a2z45ooh4i')) && entity.licenses.exists(license, license in ['/product/101001/sku/1010010001'])

Password Requirements:
Password Strength: STRONG
Minimum Length: 8 characters
Maximum Length: 100 characters
Enforce at Login: False
Allow Password Reuse: False
Password Expiration: Never
-------------------------

Policy: policies/awazjjhiasrovqgudcjnvrfpuefaq
Organization Unit: orgUnits/03ph8a2z45ooh4i
Applies to: entity.org_units.exists(org_unit, org_unit.org_unit_id == orgUnitId('03ph8a2z45ooh4i')) && !entity.licenses.exists(license, license in ['/product/101001/sku/1010010001'])

Password Requirements:
Password Strength: STRONG
Minimum Length: 8 characters
Maximum Length: 100 characters
Enforce at Login: False
Allow Password Reuse: False
Password Expiration: Never
-------------------------

Policy: policies/agazjjhiataz7hv7eojnvrfpuefaq
Organization Unit: orgUnits/03ph8a2z45ooh4i
Applies to: entity.org_units.exists(org_unit, org_unit.org_unit_id == orgUnitId('03ph8a2z45ooh4i'))

Password Requirements:
Password Strength: WEAK
Minimum Length: 8 characters
Maximum Length: 100 characters
Enforce at Login: False
Allow Password Reuse: False
Password Expiration: Never
-------------------------
====================================================================================================
DRIFT DETECTED: THE CURRENT STATE DOES NOT ALIGN WITH THE DESIRED STATE FOR SOME POLICIES
====================================================================================================
THIS IS A DRIFT DETECTION RUN. NO CHANGES WILL BE MADE

Name                           Value
----                           -----
ExitLogs                       {Policy policies/awazjjhiasxmtuoibsjnvrfpuefaq - Password Strength: CURRENT: STRONG -> DESIRED: ENABLED, Policy … 
ExitCode                       2 -->



Get-PasswordPolicy `
    -DesiredPasswordStrengthEnforced $true `
    -DesiredMinLength 8 `
    -DesiredMaxLength 100 `
    -DesiredEnforceNextSignIn $false `
    -DesiredPasswordReuseAllowed $false `
    -DesiredPasswordExpirationDays 0
