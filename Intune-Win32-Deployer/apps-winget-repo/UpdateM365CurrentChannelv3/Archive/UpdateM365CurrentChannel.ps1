# Set the path to the Office click-to-run exe
$officeExePath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"

# Set the path to the registry key for the Office installation
$officeRegKey = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"

# Get the current version of Office
$currentVersion = (Get-ItemProperty -Path $officeRegKey).ProductReleaseId

# Set the version to update to
$updateVersion = "Current"

# Update the registry key with the new version
Set-ItemProperty -Path $officeRegKey -Name "UpdateToVersion" -Value $updateVersion

# Run the Office click-to-run exe with the update command
& $officeExePath /update

# Wait for the update to complete
Start-Sleep -Seconds 300

# Get the new version of Office
$newVersion = (Get-ItemProperty -Path $officeRegKey).ProductReleaseId

# Output the old and new versions of Office
Write-Host "Office updated from version $currentVersion to version $newVersion."
