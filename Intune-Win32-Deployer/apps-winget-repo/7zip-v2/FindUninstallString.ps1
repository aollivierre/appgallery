#Unique Tracking ID: 11fa8658-f40b-4ecb-a8d1-2c47d2e40880, Timestamp: 2024-03-19 14:18:39
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$uninstallString = $null

foreach ($key in $uninstallKeys) {
    Get-ChildItem -Path $key |
    ForEach-Object {
        $app = Get-ItemProperty -Path $_.PsPath
        if ($app.DisplayName -like "*7-zip*") {
            $uninstallString = $app.UninstallString
            break
        }
    }
    
    if ($uninstallString) {
        break
    }
}

if ($null -ne $uninstallString) {
    Write-Host "Found uninstall string: $uninstallString"
    # Execute the uninstall command
    # & cmd /c $uninstallString "/qn"
} else {
    Write-Host "Uninstall string not found."
}
