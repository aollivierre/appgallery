#Unique Tracking ID: a5509187-ae6e-4af4-a7fb-e309c2c7f73f, Timestamp: 2024-04-03 09:44:46
# Start the process, wait for it to complete, and optionally hide the window


# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden



$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
