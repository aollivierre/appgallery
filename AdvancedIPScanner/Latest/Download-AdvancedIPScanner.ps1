start-bitstransfer -source "https://download.advanced-ip-scanner.com/download/files/Advanced_IP_Scanner_2.5.4594.1.exe" -Destination "c:\nova\ipscanner.exe"


cmd /c "if not exist "c:\nova" mkdir "c:\nova" & powershell.exe -Command "start-bitstransfer -source 'https://download.advanced-ip-scanner.com/download/files/Advanced_IP_Scanner_2.5.4594.1.exe' -Destination 'c:\nova\ipscanner.exe'""


cmd /c "if not exist "c:\nova" mkdir "c:\nova" & powershell.exe -Command "start-bitstransfer -source 'https://download.advanced-ip-scanner.com/download/files/Advanced_IP_Scanner_2.5.4594.1.exe' -Destination 'c:\nova\ipscanner.exe' ; start-process 'c:\nova\ipscanner.exe'

