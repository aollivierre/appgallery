# %SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -File "install.ps1" -PrinterName "HP LaserJet P3015 - Finance - New" -PrinterIPAddress "192.168.53.20" -PortName "IP_192.168.53.20" -DriverName "HP Universal Printing PCL 6" -InfPathRelative "Driver\hpcu270u.inf" -InfFileName "hpcu270u.inf" -DriverIdentifier "amd64_3e20dbae029ad04a"


# powershell.exe -executionpolicy bypass -File "install.ps1" -PrinterName "HP LaserJet P3015 - Finance - New" -PrinterIPAddress "192.168.53.20" -PortName "IP_192.168.53.20" -DriverName "HP Universal Printing PCL 6" -InfPathRelative "Driver\hpcu270u.inf" -InfFileName "hpcu270u.inf" -DriverIdentifier "amd64_3e20dbae029ad04a"



.\install.ps1 -PrinterName "HP LaserJet P3015 - Finance - New" `
              -PrinterIPAddress "192.168.53.20" `
              -PortName "IP_192.168.53.20" `
              -DriverName "HP Universal Printing PCL 6" `
              -InfPathRelative "Driver\hpcu270u.inf" `
              -InfFileName "hpcu270u.inf" `
              -DriverIdentifier "amd64_3e20dbae029ad04a"



# # Define the path to the printer configuration JSON file
# $printerConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "printer.json"

# # $params = Get-Content $printerConfigPath | ConvertFrom-Json -AsHashtable
# $params = Get-Content $printerConfigPath | ConvertFrom-Json


# .\install.ps1 @params