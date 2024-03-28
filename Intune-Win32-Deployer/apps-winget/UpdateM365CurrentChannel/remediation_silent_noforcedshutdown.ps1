# PowerShell script to update Microsoft 365 (Office 365) apps to the latest build and channel interactively.

param (
    [ValidateSet("Deferred", "FirstReleaseDeferred", "Current", "FirstReleaseCurrent")]
    [string]$channel = "Current"
)

# Define the CDN Base URLs for the various update channels.
$channelUrls = @{
    'Deferred'            = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
    'FirstReleaseDeferred'= 'http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf';
    'Current'             = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
    'FirstReleaseCurrent' = 'http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be';
}

# Define the path for OfficeC2RClient.exe
$officeC2RClientPath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"

# Change the Office 365 update channel with interaction.
# & $officeC2RClientPath /changesetting Channel=$channel displaylevel=true forceappshutdown=false
Write-Host "Running OfficeC2RClient.exe to update the channel"
& $officeC2RClientPath /changesetting Channel=$channel displaylevel=false forceappshutdown=false updatepromptuser=false

# Update Office 365 update settings for the current user with interaction.
# & $officeC2RClientPath /update user displaylevel=true forceappshutdown=false
Write-Host "Running OfficeC2RClient.exe to update M365 apps to latest"
& $officeC2RClientPath /update user displaylevel=false forceappshutdown=false updatepromptuser=false

# Update the registry values to set the Office 365 update channel.
$registryPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
Set-ItemProperty -Path $registryPath -Name "CDNBaseUrl" -Value $channelUrls[$channel]
Set-ItemProperty -Path $registryPath -Name "UpdateChannel" -Value $channelUrls[$channel]

# Set the update branch for Office 2016 to the "Current" channel.
$officeUpdatePath = "HKLM:\Software\policies\microsoft\office\16.0\common\officeupdate"
if (-not (Test-Path $officeUpdatePath)) {
    New-Item -Path $officeUpdatePath -Force
}
Set-ItemProperty -Path $officeUpdatePath -Name "updatebranch" -Value $channel

# Get the directory of the current script.
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# If there's a setup.exe in the same directory as this script, configure it using Current.xml.
if (Test-Path "$scriptDirectory\setup.exe") {
    Write-Host "Running ODT setup.exe with current XML"
    & "$scriptDirectory\setup.exe" /configure "$scriptDirectory\Current.xml"
}

Write-Output "The Office 365 update channel has been changed to $channel."
Write-Output "Office 365 apps are being updated to the latest version for this channel. This may take some time."
