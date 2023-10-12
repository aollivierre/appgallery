$msiPath = Resolve-Path ".\TV.msi"
$settingsFilePath = Resolve-Path ".\s.tvopt"
Start-Process -FilePath "MSIEXEC.EXE" -ArgumentList "/i", $msiPath, "/qn", "CUSTOMCONFIGID=he26pyq", "SETTINGSFILE=$settingsFilePath" -Wait
Start-Sleep -Seconds 30
Start-Process -FilePath "C:\Program Files (x86)\TeamViewer\TeamViewer.exe" -ArgumentList "assignment", "--id", "0001CoABChB_v5MwSa8R7o8P_rKIEvk7EigIACAAAgAJACy2Zi09RdZnXEaaCiwaca_tqmQwD_Jl-MczmvzG-wSzGkB8W7SmmlegzfK9r1qmVL39mYxWpE434_lZbmR7-_u8wLAjko6jO8YAVCA91RlMOsBp9NUzSkwYqzplaRat5iR7IAEQoJnZ0wY"