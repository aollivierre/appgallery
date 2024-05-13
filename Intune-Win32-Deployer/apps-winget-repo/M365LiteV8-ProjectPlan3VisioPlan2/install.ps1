#Unique Tracking ID: 0cb9a91b-5afd-47f4-916a-c471eaafbbd3, Timestamp: 2024-04-02 08:12:05
# Resolve the paths for the current directory
# $sPath = Resolve-Path ".\s.exe"
# $xmlPath = Resolve-Path ".\c.xml"

# Start the process, wait for it to complete, and hide the window
# Start-Process -FilePath $sPath -ArgumentList "/configure", $xmlPath -Wait -WindowStyle Hidden



# Start the process, wait for it to complete, and hide the window
Start-Process -FilePath ".\s.exe" -ArgumentList "/configure", ".\c.xml" -Wait -WindowStyle Hidden
