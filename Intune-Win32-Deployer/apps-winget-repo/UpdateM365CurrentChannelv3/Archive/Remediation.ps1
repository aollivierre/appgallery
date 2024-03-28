# PowerShell script to update Microsoft 365 (Office 365) apps to the latest build and channel.

param (
    [ValidateSet("Deferred","FirstReleaseDeferred","Current","FirstReleaseCurrent")]
    [string]$channel = "Current"
)

# Define the CDN Base URLs for the various update channels.
$channelUrls = @{
    'Deferred'            = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
    'FirstReleaseDeferred'= 'http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf';
    'Current'             = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
    'FirstReleaseCurrent' = 'http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be';
}

# Change to the directory where OfficeC2RClient.exe is located.
Set-Location "C:\Program Files\Common Files\Microsoft Shared\ClickToRun"

# Change the Office 365 update channel.
& .\OfficeC2RClient.exe /changesetting Channel=$channel

# Update Office 365 update settings for the current user.
& .\OfficeC2RClient.exe /update user /frequentupdate SCHEDULEDTASK displaylevel=False

# Alternatively, you can use the registry method to change the update channel by updating the CDNBaseUrl.
# Uncomment the lines below if you want to use this method.

$registryPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
Set-ItemProperty -Path $registryPath -Name "CDNBaseUrl" -Value $channelUrls[$channel]

Write-Output "The Office 365 update channel has been changed to $channel."
Write-Output "Office 365 apps are being updated to the latest version for this channel. This may take some time."

# Note: After running this script, you can also manually update Office 365 apps by opening any Office app and navigating to:
# File > Account > Update options > Update now