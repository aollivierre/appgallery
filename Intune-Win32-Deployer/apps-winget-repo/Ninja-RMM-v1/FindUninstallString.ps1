#Unique Tracking ID: e4bf52f8-ed96-4501-8b96-12e1248f918e, Timestamp: 2024-03-28 12:12:52
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
