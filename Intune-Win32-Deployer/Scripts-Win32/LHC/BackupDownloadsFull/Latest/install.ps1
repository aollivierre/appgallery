# $sigPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Signatures"; if (Test-Path $sigPath) { $odFolder = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName; $odPath = if ($odFolder) { Join-Path $odFolder "Documents\OutlookSignatures" } else { "$env:USERPROFILE\Documents\OutlookSignatures" }; if (-not (Test-Path $odPath)) { New-Item -ItemType Directory -Force -Path $odPath | Out-Null }; Copy-Item -Path "$sigPath\*" -Destination $odPath -Recurse -Force }

# $oneDrivePath = (Get-ChildItem -Path "$env:USERPROFILE" -Filter "OneDrive - *" -Directory).FullName
# $downloadsPath = Join-Path $env:USERPROFILE "Downloads"
# $backupPath = Join-Path $oneDrivePath "DownloadsBackup"

# if (Test-Path $downloadsPath) {
#     if (-not (Test-Path $backupPath)) {
#         New-Item -ItemType Directory -Force -Path $backupPath | Out-Null
#     }
#     Copy-Item -Path "$downloadsPath\*" -Destination $backupPath -Recurse -Force
# }


$od=(Get-ChildItem "$env:USERPROFILE" -Filter "OneDrive - *" -dir).FullName;$dp="$env:USERPROFILE\Downloads";$bp=Join-Path $od "DownloadsBackup";if (Test-Path $dp) {if (-not (Test-Path $bp)) {New-Item -ItemType dir -Force -Path $bp | Out-Null};Copy-Item -Path "$dp\*" -Dest $bp -Recurse -Force}