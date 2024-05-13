#Unique Tracking ID: 8386032e-478f-4799-ab95-fdc1080a3eb8, Timestamp: 2024-04-02 08:58:43
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$softwareNamePattern = "*Paint*"

# Function to check for any installed version of Ninja
function Find-Ninja {
    param (
        [string[]]$RegistryPaths,
        [string]$SoftwareNamePattern
    )

    foreach ($path in $RegistryPaths) {
        $items = Get-ChildItem -Path $path

        foreach ($item in $items) {
            $app = Get-ItemProperty -Path $item.PsPath
            if ($app.DisplayName -like $SoftwareNamePattern) {
                return @{
                    Found           = $true
                    DisplayName     = $app.DisplayName
                    Version         = $app.DisplayVersion
                    InstallLocation = $app.InstallLocation
                }
            }
        }
    }

    return @{Found = $false }
}

# Main script execution
$findResult = Find-Ninja -RegistryPaths $registryPaths -SoftwareNamePattern $softwareNamePattern

if ($findResult.Found) {
    Write-Output "Ninja is installed. Details:"
    Write-Output "Name: $($findResult.DisplayName)"
    Write-Output "Version: $($findResult.Version)"
    Write-Output "Install Location: $($findResult.InstallLocation)"
}
else {
    Write-Output "Ninja is not installed."
}



# Ninja is installed. Details:
# Name: NinjaRMMAgent
# Version: 5.7.8836
# Install Location: C:\Program Files (x86)/bellwoodsmainoffice-5.7.8836
