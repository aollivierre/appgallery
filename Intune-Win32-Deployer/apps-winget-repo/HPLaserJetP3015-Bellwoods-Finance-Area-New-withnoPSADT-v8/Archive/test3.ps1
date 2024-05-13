# Path to PsExec
$PsExecPath = "C:\Users\aollivierre\AppData\Local\Intune-Win32-Deployer\apps-winget-repo\HPLaserJetP3015-Bellwoods-Finance-Area-New-withnoPSADT-v7\Private\PsExec64.exe"
# PowerShell command you want to run as SYSTEM
$Command = "Get-Service | Where-Object { `$_.Status -eq 'Running' } | Select-Object DisplayName, Status"

# Command line to invoke PowerShell as SYSTEM using PsExec
$CommandLine = "-i -s powershell.exe -NoExit -Command `"$Command`""

# Using Start-Process to invoke PsExec, which will prompt for elevation if not already running as admin
Start-Process -FilePath $PsExecPath -ArgumentList $CommandLine -Wait
