# Start the process, wait for it to complete, and optionally hide the window

$d_1001 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d_1001\ServiceUI.exe" -ArgumentList "$d_1001\Deploy-Application.exe" -Wait -WindowStyle Hidden