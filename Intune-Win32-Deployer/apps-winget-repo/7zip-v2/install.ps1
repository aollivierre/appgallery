#Unique Tracking ID: 2602c564-1ffa-4331-9b87-a8805aee5f9c, Timestamp: 2024-03-19 14:18:39
# Start the process, wait for it to complete, and optionally hide the window


# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden



$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
