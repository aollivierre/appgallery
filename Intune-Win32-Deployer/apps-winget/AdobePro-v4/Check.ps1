#Unique Tracking ID: 2acf7a98-4f65-416f-993f-d832394dfecc, Timestamp: 2024-04-04 18:30:45
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
$targetSoftwareName = "Adobe Acrobat (64-bit)"
$minimumVersion = New-Object Version "24.001.20604"

# Function to check for AdobeAcrobatPro64bit installation and version
function AdobeAcrobatPro64bitInstallation {
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
$installationCheck = AdobeAcrobatPro64bitInstallation -RegistryPaths $registryPaths -SoftwareName $targetSoftwareName -MinimumVersion $minimumVersion

if ($installationCheck.IsInstalled) {
    Write-Output "AdobeAcrobatPro64bit version $($installationCheck.Version) or later is installed."
    exit 0
} else {
    Write-Output "AdobeAcrobatPro64bit version $minimumVersion or later is not installed."
    exit 1
}
