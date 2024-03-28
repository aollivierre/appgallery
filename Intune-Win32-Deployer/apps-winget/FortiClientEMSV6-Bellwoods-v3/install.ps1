#Unique Tracking ID: 47c68641-620d-4938-8eeb-342f9111cfe1, Timestamp: 2024-02-26 23:05:50
# Start the process, wait for it to complete, and optionally hide the window

$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
Start-Process -FilePath "$d_1002\Deploy-Application.exe" -Wait -WindowStyle Hidden
