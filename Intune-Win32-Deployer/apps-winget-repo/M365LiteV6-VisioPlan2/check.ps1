#Unique Tracking ID: 4d3b48c5-0c99-4672-a5c5-46e3cb49784b, Timestamp: 2024-02-21 15:51:45
if((Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"|Get-ItemProperty|Where-Object{$_.DisplayName -match "Microsoft 365 Apps" })){ Write-Output "f";exit 0}else{exit 1}