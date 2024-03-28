#Unique Tracking ID: 67ac28e1-1b2e-4bbc-a68e-39e0d5e387d8, Timestamp: 2024-02-15 13:14:52
# Start the process, wait for it to complete, and optionally hide the window

$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
