#Unique Tracking ID: 4063c752-cc15-4855-ab83-410142e59c16, Timestamp: 2024-02-15 12:55:52
# Start the process, wait for it to complete, and optionally hide the window

$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
