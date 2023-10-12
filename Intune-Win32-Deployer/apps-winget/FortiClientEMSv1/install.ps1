# Start the process, wait for it to complete, and optionally hide the window

$d = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Start-Process -FilePath "$d\ServiceUI.exe" -ArgumentList "$d\Deploy-Application.exe" -Wait -WindowStyle Hidden