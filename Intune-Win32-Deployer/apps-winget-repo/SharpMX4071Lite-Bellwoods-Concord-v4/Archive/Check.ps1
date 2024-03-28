#Unique Tracking ID 9b27c0a9-262c-43e3-9585-b8df996f3ce6

$pName = "SHARP Concord"; $pRegKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$pName"; if ((Get-ItemProperty -Path $pRegKeyPath -Name "Name" -ErrorAction SilentlyContinue)."Name" -eq $pName) { Write-Output "Printer '$pName' detected."; exit 0 } else { exit 1 }