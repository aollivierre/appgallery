#Unique Tracking ID: 0dd7a5e2-d94f-47b5-bd71-7502f65e287a, Timestamp: 2024-04-02 08:58:43
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$uninstallString = $null

foreach ($key in $uninstallKeys) {
    Get-ChildItem -Path $key |
    ForEach-Object {
        $app = Get-ItemProperty -Path $_.PsPath
        if ($app.DisplayName -like "*Paint*") {
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



# Found uninstall string: "C:\Program Files (x86)\bellwoodsmainoffice-5.7.8836\uninstall.exe"
