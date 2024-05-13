#Unique Tracking ID: 38a3388c-26f3-4290-a4f0-fc32b3c23723, Timestamp: 2024-03-05 11:11:26
<#
.SYNOPSIS
Checks for the installation of FortiClient version 7.2.3.0929 or later on the system.

.DESCRIPTION
This script searches the system's uninstallation registry keys for FortiClient and checks if the installed version is 7.2.3.0929 or later. If a qualifying version is found, the script exits with code 0. Otherwise, it exits with code 1.

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
$targetSoftwareName = "FortiClient"
$minimumVersion = New-Object Version "7.2.3.0929"

# Function to check for FortiClient installation and version
function Get-FortiClientInstallation {
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
$installationCheck = Get-FortiClientInstallation -RegistryPaths $registryPaths -SoftwareName $targetSoftwareName -MinimumVersion $minimumVersion

if ($installationCheck.IsInstalled) {
    Write-Output "FortiClient version $($installationCheck.Version) or later is installed."
    exit 0
} else {
    # Write-Output "FortiClient version 7.2.3.0929 or later is not installed."
    exit 1
}