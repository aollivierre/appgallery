$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$regKeyPath = "HKLM:\SOFTWARE\Fortinet\FortiClient\Sslvpn\Tunnels\CHFC-VPN-Entra-SAML-SSO-corp"
$fortiProductInstalled = $false
$fortiProductDetails = @{}

foreach ($key in $uninstallKeys) {
    Get-ChildItem -Path $key |
    ForEach-Object {
        $app = Get-ItemProperty -Path $_.PsPath
        if ($app.DisplayName -like "*Forti*") {
            $fortiProductInstalled = $true
            $fortiProductDetails.DisplayName = $app.DisplayName
            $fortiProductDetails.PSChildName = $app.PSChildName
            break
        }
    }
    
    if ($fortiProductInstalled) {
        break
    }
}

# Check if the specific registry key exists
$regKeyExists = Test-Path -Path $regKeyPath

# Conditionally proceed based on the checks
if ($fortiProductInstalled -and $regKeyExists) {
    Write-Output "A Forti product is installed with details: $($fortiProductDetails.DisplayName), Product Code: $($fortiProductDetails.PSChildName). Also, the required registry key exists."
    # Proceed with your script logic here
} elseif ($fortiProductInstalled) {
    # Write-Output "A Forti product is installed with details: $($fortiProductDetails.DisplayName), Product Code: $($fortiProductDetails.PSChildName), but the required registry key does not exist."
    # Handle the absence of the registry key here
    exit 1
} else {
    Write-Output "No Forti product is installed or the required registry key does not exist."
    # Handle the case where no Forti product is installed
}
