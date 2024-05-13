#Unique Tracking ID: bcca43ab-16c4-4be6-afbe-dfd0dbca8c23, Timestamp: 2024-02-23 11:50:16
$PackageName = "PR4B_BackupDownloadsFolder"
$PackageUniqueGUID = "f18f8d73-cf1d-41d9-b8a1-cc6d9e7873ce"
# $Version = 1

$schtaskName = "$PackageName - $PackageUniqueGUID"
# $schtaskDescription = "Version $Version"

# check if running as system
function Test-RunningAsSystem {
	[CmdletBinding()]
	param()
	process {
		return [bool]($(whoami -user) -match "S-1-5-18")
	}
}

if(Test-RunningAsSystem){$Path_local = "$ENV:Programfiles\_MEM"}
else{$Path_local = "$ENV:LOCALAPPDATA\_MEM"}

Start-Transcript -Path "$Path_local\Log\uninstall\$schtaskName-uninstall.log" -Force

# $Task_Name = "$PackageName"
$Task_Name = "$schtaskName"
Unregister-ScheduledTask -TaskName $Task_Name -Confirm:$false

# remove local Path
$Path_PR = "$Path_local\Data\PR_$schtaskName"
Remove-Item -path $Path_PR -Recurse -Force

Stop-Transcript
