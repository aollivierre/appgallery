$PackageName = "PR4B_BitLockerRecoveryEscrow"
$Version = "1"

# Check if Task exist with correct version
$Task_Name = "$PackageName - 01dc2c5b-df9b-46c0-93c1-d8a99f7e18c0"
$Task_Name
$Task_existing = Get-ScheduledTask -TaskName $Task_Name -ErrorAction SilentlyContinue
if($Task_existing.Description -like "Version $Version*"){
    Write-Host "Found it!"
    exit 0
}else{exit 1}