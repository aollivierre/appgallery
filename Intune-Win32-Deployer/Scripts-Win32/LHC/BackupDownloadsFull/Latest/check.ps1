# $sigPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"; if (Test-Path $sigPath) { $odFolder = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName; $odPath = if ($odFolder) { Join-Path $odFolder "Documents\OutlookSignatures" } else { "$env:USERPROFILE\Documents\OutlookSignatures" }; if (Test-Path $odPath) { $backupFiles = Get-ChildItem -Path $odPath -Recurse -File; if ($backupFiles.Count -gt 0) { Write-Output "Backup Outlook Signatures detected at $odPath."; exit 0 } else { exit 1 } } else { exit 1 } } else { exit 1 }

# $downloadsBackupPath = Join-Path ((Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName) "DownloadsBackup"
# if (Test-Path $downloadsBackupPath) {
#     $backupFiles = Get-ChildItem -Path $downloadsBackupPath -Recurse -File
#     if ($backupFiles.Count -gt 0) {
#         Write-Output "DownloadsBackup folder detected with files at $downloadsBackupPath."
#         exit 0
#     } else {
#         exit 1
#     }
# } else {
#     exit 1
# }



$bp=Join-Path ((Get-ChildItem "$env:USERPROFILE" -Filter "OneDrive - *" -dir).FullName) "DownloadsBackup";if (Test-Path $bp) {if ((Get-ChildItem -Path $bp -Recurse -File).Count -gt 0) {Write-Output "DownloadsBackup folder detected with files at $bp.";exit 0}else{exit 1}}else{exit 1}

