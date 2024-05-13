#Unique Tracking ID: 0d6b18d6-960f-418a-89a9-a67f530b49e0, Timestamp: 2024-04-02 11:14:48
# Start the process, wait for it to complete, and optionally hide the window


# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden



$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
