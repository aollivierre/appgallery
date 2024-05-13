#Unique Tracking ID: 1751fb8f-7c77-42cf-8323-1378db9c932b, Timestamp: 2024-04-03 02:23:46
# Start the process, wait for it to complete, and optionally hide the window


# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden



$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
