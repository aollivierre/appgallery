$PackageName = "PR4B-SetAdobeReaderPDFDefault"
# $Version = "1"

# Check if Task exist with correct version
$Task_Name = "$PackageName - 215c2d78-1295-439e-8ff5-74e423f8717f"

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

Start-Transcript -Path "$Path_local\Log\uninstall\$PackageName-uninstall.log" -Force

# $Task_Name = "$PackageName"
$Task_Name = "$PackageName - 215c2d78-1295-439e-8ff5-74e423f8717f"
Unregister-ScheduledTask -TaskName $Task_Name -Confirm:$false

# remove local Path
$Path_PR = "$Path_local\Data\PR_$PackageName"
Remove-Item -path $Path_PR -Recurse -Force

Stop-Transcript