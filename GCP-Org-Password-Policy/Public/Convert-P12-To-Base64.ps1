# # Replace path with your P12 file location
# $p12Path = "C:\Users\Personal\Downloads\mindful-life-450521-e0-c5c74fa10e5c.p12"
# $base64Value = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p12Path))

# # Output to a file (optional)
# $base64Value | Out-File "p12_base64.txt"

# # Display the value
# Write-Host $base64Value