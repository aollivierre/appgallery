# PowerShell script to detect the current Microsoft 365 (Office 365) update channel.

# Define the CDN Base URLs for the various update channels for reference.
$channelUrls = @{
    'Semi-Annual Channel' = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
    'Semi-Annual Channel (Targeted)' = 'http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf';
    'Monthly Channel' = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
    'Monthly Channel (Targeted)' = 'http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be';
    'Beta Channel' = 'http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f';
}

# Fetch the current CDNBaseUrl from the registry.
$registryPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
$cdnBaseUrl = Get-ItemProperty -Path $registryPath -Name "CDNBaseUrl" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty CDNBaseUrl

# Determine the current update channel based on the CDNBaseUrl.
$currentChannel = $channelUrls.GetEnumerator() | Where-Object { $_.Value -eq $cdnBaseUrl } | Select-Object -ExpandProperty Key

if (-not $currentChannel) {
    Write-Output "Unable to determine the current Office 365 update channel from CDNBaseUrl."
} else {
    Write-Output "The current Office 365 update channel (from CDNBaseUrl) is: $currentChannel"
}

# Check the update policy from the Microsoft Policy Manager registry path.
$policyManagerPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\office16v2~Policy~L_MicrosoftOfficemachine~L_Updates"
$updatePolicyValue = Get-ItemProperty -Path $policyManagerPath -ErrorAction SilentlyContinue | Select-Object -ExpandProperty updatebranch

if ($updatePolicyValue) {
    Write-Output "The Office 365 update policy (from PolicyManager) is set to: $updatePolicyValue"
} else {
    Write-Output "Unable to determine the Office 365 update policy from PolicyManager."
}
