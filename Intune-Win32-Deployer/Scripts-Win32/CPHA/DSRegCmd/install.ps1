# Start the process, wait for it to complete, and optionally hide the window
Start-Process -FilePath ".\ServiceUI.exe" -ArgumentList ".\Deploy-Application.exe" -Wait -WindowStyle Hidden