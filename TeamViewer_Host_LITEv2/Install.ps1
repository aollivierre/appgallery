$msiPath = Resolve-Path ".\TV.msi"
$settingsFilePath = Resolve-Path ".\s.tvopt"
Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList "/i", $msiPath, "/qn", "CUSTOMCONFIGID=enter your config ID for the specific module from here https://login.teamviewer.com/nav/deploy/modules", "SETTINGSFILE=$settingsFilePath" -Wait
Start-Sleep -Seconds 30
Start-Process -FilePath "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" -ArgumentList "assignment", "--id", "enter your assignment ID from https://login.teamviewer.com/nav/deploy/assignments"