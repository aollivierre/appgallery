# Resolve the paths for the current directory
# $sPath = Resolve-Path ".\s.exe"
# $xmlPath = Resolve-Path ".\c.xml"

# Start the process, wait for it to complete, and hide the window
# Start-Process -FilePath $sPath -ArgumentList "/configure", $xmlPath -Wait -WindowStyle Hidden



# Start the process, wait for it to complete, and hide the window
Start-Process -FilePath ".\s.exe" -ArgumentList "/configure", ".\c.xml" -Wait -WindowStyle Hidden