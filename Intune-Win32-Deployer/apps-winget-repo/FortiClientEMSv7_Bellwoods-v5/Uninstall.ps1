#Unique Tracking ID: 38a3388c-26f3-4290-a4f0-fc32b3c23723, Timestamp: 2024-03-05 11:11:26
$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe -DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden

# Start-Process -FilePath ".\sara\SaRAcmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden
# Start-Process -FilePath "C:\Users\AOllivierre_CloudAdm\Downloads\SaRACmd_17_01_0495_021\SaRACmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden



Start-Process -FilePath "$d_1002\Deploy-Application.exe" -ArgumentList "-DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden