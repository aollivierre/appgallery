$PackageName = "PR4B_RemoveWSUS"
$Version = "8"

# Check if Task exist with correct version
$Task_Name = "$PackageName - d9900665-e3fb-4820-8a47-760dc6e28ffa"
$Task_Name
$Task_existing = Get-ScheduledTask -TaskName $Task_Name -ErrorAction SilentlyContinue
if($Task_existing.Description -like "Version $Version*"){
    Write-Host "Found it!"
    exit 0
}else{exit 1}