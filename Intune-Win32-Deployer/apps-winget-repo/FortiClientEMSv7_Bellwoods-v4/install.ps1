#Unique Tracking ID: 9e17d4ea-6b5c-4d4a-bac8-f89387197cd4, Timestamp: 2024-02-26 23:08:39
# Start the process, wait for it to complete, and optionally hide the window

$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden