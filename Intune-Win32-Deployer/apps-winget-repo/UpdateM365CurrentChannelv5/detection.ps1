try {
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    $policyManagerPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\office16v2~Policy~L_MicrosoftOfficemachine~L_Updates"
    $officeUpdatePath = "HKLM:\Software\policies\microsoft\office\16.0\common\officeupdate"

    # Define the CDN Base URL for the Monthly Channel.
    $monthlyChannelUrl = 'http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60'

    # Fetch the current CDNBaseUrl and UpdateChannel from the registry.
    $cdnBaseUrl = (Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue).CDNBaseUrl
    $updateChannel = (Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue).UpdateChannel

    # Check if the CDNBaseUrl and UpdateChannel are set to the Monthly Channel.
    $isCDNBaseUrlMonthlyChannel = $cdnBaseUrl -eq $monthlyChannelUrl
    $isUpdateChannelMonthlyChannel = $updateChannel -eq $monthlyChannelUrl

    # Check the update policy from the Microsoft Policy Manager registry path.
    $updatePolicyValue = (Get-ItemProperty -Path $policyManagerPath -ErrorAction SilentlyContinue).updatebranch
    $isUpdatePolicyPresent = $null -ne $updatePolicyValue

    # Check the update branch for Office 2016.
    $updateBranch = (Get-ItemProperty -Path $officeUpdatePath -ErrorAction SilentlyContinue).updatebranch
    $isUpdateBranchCurrent = $updateBranch -eq "Current"

    # Provide feedback for documentation purposes.
    if ($isCDNBaseUrlMonthlyChannel) {
        # Write-Host "The CDNBaseUrl is set to the Monthly Channel."
    } else {
        # Write-Host "The CDNBaseUrl is NOT set to the Monthly Channel."
    }

    if ($isUpdateChannelMonthlyChannel) {
        # Write-Host "The UpdateChannel is set to the Monthly Channel."
    } else {
        # Write-Host "The UpdateChannel is NOT set to the Monthly Channel."
    }

    if ($isUpdatePolicyPresent) {
        # Write-Host "The update policy in Microsoft Policy Manager is present."
    } else {
        # Write-Host "The update policy in Microsoft Policy Manager is NOT present."
    }

    if ($isUpdateBranchCurrent) {
        # Write-Host "The update branch for Office 2016 is set to Current."
    } else {
        # Write-Host "The update branch for Office 2016 is NOT set to Current."
    }

    # Since remediation will always occur, just provide feedback and exit with a success code.
    exit 0

} catch {
    # Write-Error "An error occurred: $_"
    exit 2
}
