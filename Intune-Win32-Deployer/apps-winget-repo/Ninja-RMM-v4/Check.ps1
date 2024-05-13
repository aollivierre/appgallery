#Unique Tracking ID: 49f364ec-4608-44ee-b8e3-94694b837753, Timestamp: 2024-03-28 13:56:17
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
$targetSoftwareName = "NinjaRMMAgent"
$minimumVersion = New-Object Version "5.7.8836"

# Function to check for NinjaRMMAgent installation and version
function Get-NinjaRMMAgentInstallation {
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
$installationCheck = Get-NinjaRMMAgentInstallation -RegistryPaths $registryPaths -SoftwareName $targetSoftwareName -MinimumVersion $minimumVersion

if ($installationCheck.IsInstalled) {
    Write-Output "NinjaRMMAgent version $($installationCheck.Version) or later is installed."
    exit 0
} else {
    Write-Output "NinjaRMMAgent version $minimumVersion or later is not installed."
    exit 1
}
