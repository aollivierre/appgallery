$PackageName = "PR4B_BackupDownloadsFolder"
$PackageUniqueGUID = "f18f8d73-cf1d-41d9-b8a1-cc6d9e7873ce"
$Version = 1

$schtaskName = "$PackageName - $PackageUniqueGUID"

# Check if Task exist with correct version
# $Task_Name = $schtaskName
# $Task_Name
$Task_existing = Get-ScheduledTask -TaskName $schtaskName -ErrorAction SilentlyContinue
if($Task_existing.Description -like "Version $Version*"){
    Write-Host "Found it!"
    exit 0
}else{exit 1}