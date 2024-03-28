#Unique Tracking ID: cacd55af-e4ed-4f27-af39-d1643565b7a6, Timestamp: 2024-02-28 13:53:29
$PackageName = "PR4B-SetAdobeReaderPDFDefault"
$Version = "1"

# Check if Task exist with correct version
$Task_Name = "$PackageName - 215c2d78-1295-439e-8ff5-74e423f8717f"
# $Task_Name
$Task_existing = Get-ScheduledTask -TaskName $Task_Name -ErrorAction SilentlyContinue
if($Task_existing.Description -like "Version $Version*"){
    Write-Host "Found it!"
    exit 0
}else{exit 1}
