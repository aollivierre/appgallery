#Unique Tracking ID: 61834768-ffda-4322-a9ee-58a47d646d1c, Timestamp: 2024-02-21 16:11:33
$PackageName = "WindowsPackageManager"
$Path_local = "$Env:Programfiles\_MEM"
Start-Transcript -Path "$Path_local\Log\uninstall\$PackageName-uninstall.log" -Force

Remove-AppPackage -Package "Microsoft.DesktopAppInstaller"

Stop-Transcript
