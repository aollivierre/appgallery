try {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $policyManagerPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\office16v2~Policy~L_MicrosoftOfficemachine~L_Updates"


    #  # Define the CDN Base URLs for the various update channels for reference.
    #  $channelUrls = @{
    #     'Semi-Annual Channel' = 'http://officecdn.microsoft.com/pr/7ffbc6bf-bc32-4f92-8982-f9dd17fd3114';
    #     'Semi-Annual Channel (Targeted)' = 'http://officecdn.microsoft.com/pr/b8f9b850-328d-4355-9145-c59439a0c4cf';
    #     'Monthly Channel' = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60';
    #     'Monthly Channel (Targeted)' = 'http://officecdn.microsoft.com/pr/64256afe-f5d9-4f86-8936-8840a6a4f5be';
    #     'Beta Channel' = 'http://officecdn.microsoft.com/pr/5440fd1f-7ecb-4221-8110-145efaa6372f';
    # }

    # Define the CDN Base URL for the Monthly Channel.
    $monthlyChannelUrl = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60'

    # Fetch the current CDNBaseUrl from the registry.
    $cdnBaseUrl = (Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue).CDNBaseUrl

    # Check if the CDNBaseUrl is set to the Monthly Channel.
    $isCDNBaseUrlMonthlyChannel = $cdnBaseUrl -eq $monthlyChannelUrl

    # Check the update policy from the Microsoft Policy Manager registry path.
    $updatePolicyValue = (Get-ItemProperty -Path $policyManagerPath -ErrorAction SilentlyContinue).updatebranch
    $isUpdatePolicyPresent = $null -ne $updatePolicyValue

    # Provide feedback for documentation purposes.
    if ($isCDNBaseUrlMonthlyChannel) {
        Write-Host "The CDNBaseUrl is set to the Monthly Channel."
    } else {
        Write-Host "The CDNBaseUrl is NOT set to the Monthly Channel."
    }

    if ($isUpdatePolicyPresent) {
        Write-Host "The update policy in Microsoft Policy Manager is present."
    } else {
        Write-Host "The update policy in Microsoft Policy Manager is NOT present."
    }

    # Since remediation will always occur, just provide feedback and exit with a success code.
    exit 0

} catch {
    Write-Error "An error occurred: $_"
    exit 2
}
