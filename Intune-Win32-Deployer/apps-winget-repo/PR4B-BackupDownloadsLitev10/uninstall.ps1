#Unique Tracking ID: 505c652b-4986-49e8-b0c6-96243b8ff939, Timestamp: 2024-02-24 21:07:37
# Read configuration from the JSON file
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Assign values from JSON to variables
$PackageName = $config.PackageName
$PackageUniqueGUID = $config.PackageUniqueGUID
# $Version = $config.Version

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
