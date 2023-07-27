if (Test-Path "C:\Program Files\Huntress\HuntressAgent.exe") { Write-Output "Huntress Agent found at C:\Program Files\Huntress\HuntressAgent.exe"; exit 0 } else { exit 1 }
