#Unique Tracking ID: a4b54c1d-ce76-4145-bd6c-830f380a3bcf, Timestamp: 2024-04-02 11:14:46
<#
.SYNOPSIS
Checks for the installation of 7zip versions older than 24.01.00.0.

.DESCRIPTION
This script searches the system's uninstallation registry keys for 7zip installations. 
It checks if any installed version is older than 24.01.00.0 and provides feedback based on this condition.

.NOTES
Version:        1.0
Author:         Abdullah Ollivierre
Creation Date:  2024-03-05
#>


# Define constants for registry paths and minimum required version
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$targetSoftwareName = "Bell Total Connect"
$minimumVersion = New-Object Version "22.7.13.405"

# Function to check for BellTotalConnectAgen installation and version
function BellTotalConnectAgentInstallation {
    param (
        [string[]]$RegistryPaths,
        [string]$SoftwareName,
        [version]$MinimumVersion
    )

    foreach ($path in $RegistryPaths) {
        $items = Get-ChildItem -Path $path -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PsPath -ErrorAction SilentlyContinue
            if ($app.DisplayName -like "*$SoftwareName*") {
                $installedVersion = New-Object Version $app.DisplayVersion
                if ($installedVersion -ge $MinimumVersion) {
                    return @{
                        IsInstalled = $true
                        Version = $app.DisplayVersion
                        ProductCode = $app.PSChildName
                    }
                }
            }
        }
    }

    return @{IsInstalled = $false}
}

# Main script execution block
$installationCheck = BellTotalConnectAgentInstallation -RegistryPaths $registryPaths -SoftwareName $targetSoftwareName -MinimumVersion $minimumVersion

if ($installationCheck.IsInstalled) {
    Write-Output "BellTotalConnectAgen version $($installationCheck.Version) or later is installed."
    exit 0
} else {
    Write-Output "BellTotalConnectAgen version $minimumVersion or later is not installed."
    exit 1
}
