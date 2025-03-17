Perfect! Now we're getting all the events we need. Here's a summary of what the script is now capturing:

Third-party API access events:
All third party API access blocked
All third party API access unblocked
Allow Google Sign-in only third party API access
Domain Owned Apps trust events:
Domain Owned Apps Trusted (added to trusted list)
Domain Owned Apps Not Trusted (removed from trusted list)
The script is now showing:

Full chronological history
All actors (both peleke@kemkos.com and arikeru@kemkos.com)
All organizational units affected
Timestamps and IP addresses for each change
Exported to CSV for further analysis

Get-APIControlSettings `
    -DesiredDomainOwnedAppsTrust $true `
    -DesiredBlockThirdPartyAPIAccess $true

Get-APIControlSettings `
    -DesiredDomainOwnedAppsTrust $false `
    -DesiredBlockThirdPartyAPIAccess $false
