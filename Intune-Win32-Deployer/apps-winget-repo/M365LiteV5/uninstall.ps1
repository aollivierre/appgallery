#Unique Tracking ID: 4d3b48c5-0c99-4672-a5c5-46e3cb49784b, Timestamp: 2024-02-21 15:51:45
# # Resolve the paths for the current directory
# $sPath = Resolve-Path ".\s.exe"
# $xmlPath = Resolve-Path ".\u.xml"

# # Start the process, wait for it to complete, and hide the window
# Start-Process -FilePath $sPath -ArgumentList "/configure", $xmlPath -Wait -WindowStyle Hidden


# Start the process, wait for it to complete, and hide the window
Start-Process -FilePath ".\s.exe" -ArgumentList "/configure", ".\u.xml" -Wait -WindowStyle Hidden
