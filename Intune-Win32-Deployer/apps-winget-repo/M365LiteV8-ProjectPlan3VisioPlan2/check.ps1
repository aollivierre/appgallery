#Unique Tracking ID: 15a0caf8-b653-4fcb-9f52-64dd7957d11d, Timestamp: 2024-04-02 08:12:05
if((Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"|Get-ItemProperty|Where-Object{$_.DisplayName -match "Microsoft 365 Apps" })){ Write-Output "f";exit 0}else{exit 1}
