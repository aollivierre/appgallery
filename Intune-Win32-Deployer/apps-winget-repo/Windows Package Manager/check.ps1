#Unique Tracking ID: 61834768-ffda-4322-a9ee-58a47d646d1c, Timestamp: 2024-02-21 16:11:33
$wingetexe = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe"
    if ($wingetexe.count -gt 1){
           $wingetexe = $wingetexe[-1].Path
    }

if ($wingetexe){
    Write-Host "Found it!"
}
