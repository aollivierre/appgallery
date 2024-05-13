#Unique Tracking ID: 201eaf53-add4-4a2f-81a5-381e7541f487, Timestamp: 2024-04-03 09:44:46
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
$softwareNamePattern = "*Bell*"

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
