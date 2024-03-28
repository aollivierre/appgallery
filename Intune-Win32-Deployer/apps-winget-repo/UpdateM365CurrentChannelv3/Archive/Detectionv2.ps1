try {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $policyManagerPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\office16v2~Policy~L_MicrosoftOfficemachine~L_Updates"

    # Define the CDN Base URLs for the various update channels for reference.
    $channelUrls = @{
        'Semi-Annual Channel' = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
        'Semi-Annual Channel (Targeted)' = 'http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf';
        'Monthly Channel' = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
        'Monthly Channel (Targeted)' = 'http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be';
        'Beta Channel' = 'http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f';
    }

    # Fetch the current CDNBaseUrl from the registry.
    $cdnBaseUrl = (Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue).CDNBaseUrl

    # Check if the CDNBaseUrl exists in the known channels.
    $isCDNBaseUrlCorrect = $channelUrls.Values -contains $cdnBaseUrl

    # Check the update policy from the Microsoft Policy Manager registry path.
    $updatePolicyValue = (Get-ItemProperty -Path $policyManagerPath -ErrorAction SilentlyContinue).updatebranch
    $isUpdatePolicyPresent = $null -ne $updatePolicyValue

    if ($isCDNBaseUrlCorrect -and $isUpdatePolicyPresent) {
        Write-Host "All registry keys and values are set correctly. No remediation needed."
        exit 0
    } else {
        Write-Host "Registry keys and/or values are incorrect. Remediation needed."
        exit 1
    }
} catch {
    Write-Error "An error occurred: $_"
    exit 2
}
