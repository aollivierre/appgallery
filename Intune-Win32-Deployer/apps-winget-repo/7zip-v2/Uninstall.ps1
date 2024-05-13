#Unique Tracking ID: ec3f11f8-62c9-4b52-8e16-8052206f6307, Timestamp: 2024-03-19 14:18:39
$d_1002 = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# Start-Process -FilePath "$d_1002\ServiceUI.exe" -ArgumentList "$d_1002\Deploy-Application.exe -DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden


Start-Process -FilePath "$d_1002\Deploy-Application.exe" -ArgumentList "-DeploymentType `"Uninstall`"" -Wait -WindowStyle Hidden

# Start-Process -FilePath ".\sara\SaRAcmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden
# Start-Process -FilePath "C:\Users\AOllivierre_CloudAdm\Downloads\SaRACmd_17_01_0495_021\SaRACmd.exe" -ArgumentList "-S OfficeScrubScenario -AcceptEula -OfficeVersion All" -wait -WindowStyle Hidden
