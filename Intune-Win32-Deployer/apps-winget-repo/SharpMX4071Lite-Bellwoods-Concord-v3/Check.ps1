#Unique Tracking ID ee64c5bb-4e75-4102-aa11-9544d563d3ff
$pName = "SHARP Concord"; $pRegKeyPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\$pName"; if ((Get-ItemProperty -Path $pRegKeyPath -Name "Name" -ErrorAction SilentlyContinue)."Name" -eq $pName) { Write-Output "Printer '$pName' detected."; exit 0 } else { exit 1 }