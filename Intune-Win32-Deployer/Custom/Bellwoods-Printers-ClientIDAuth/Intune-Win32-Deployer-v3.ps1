#############################################################################################################
#
#   Tool:           Intune Win32 Deployer
#   Author:         Florian Salzmann
#   Website:        http://www.scloud.work
#   Twitter:        https://twitter.com/FlorianSLZ
#   LinkedIn:       https://www.linkedin.com/in/fsalzmann/
#
#   Description:    https://scloud.work/intune-win32-deployer/
#
#############################################################################################################

# Required Modules 
# Install-Module MSAL.PS, IntuneWin32App, Microsoft.Graph.Groups, Microsoft.Graph.Intune  -Scope CurrentUser -Force

<#
    .SYNOPSIS
    Packages choco, winget and custom apps for MEM (Intune) deployment.
    Uploads the packaged into the target Intune tenant.

    .NOTES
    For details on IntuneWin32App go here: https://scloud.work/Intune-Win32-Deployer

#>



[CmdletBinding()]
Param (
    [Parameter(Mandatory = $False)]
    [System.String] $Repo_Path = "$env:LOCALAPPDATA\Intune-Win32-Deployer",

    [Parameter(Mandatory = $False)]
    [System.String] $Repo_choco = "$Repo_Path\apps-choco",

    [Parameter(Mandatory = $False)]
    [System.String] $Repo_winget = "$Repo_Path\apps-winget",

    [Parameter(Mandatory = $False)]
    [System.String] $Repo_custom = "$Repo_Path\apps-custom",

    [Parameter(Mandatory = $False)]
    [System.String] $Repo_CSV_Path = "$Repo_Path\Applications.csv",

    [Parameter(Mandatory = $False)]
    [System.String] $IntuneWinAppUtil_online = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/IntuneWinAppUtil.exe"
    
)




$AOscriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

# Start-Transcript -Path $AOscriptDirectory\Win32Deployer.log


# function IsAdmin {
#     $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
#     $principal = [Security.Principal.WindowsPrincipal] $identity
#     return $principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
# }
    
# if (-not (IsAdmin)) {
#     Write-Host "Script needs to be run as Administrator. Relaunching with admin privileges." -ForegroundColor Yellow
#     Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
#     exit
# }
    
    
function Initialize-ScriptAndLogging {
    $ErrorActionPreference = 'SilentlyContinue'
    $deploymentName = "IntuneWin32DeployerCustomlog" # Replace this with your actual deployment name
    $scriptPath = "C:\code\$deploymentName"
    # $hadError = $false
    
    try {
        if (-not (Test-Path -Path $scriptPath)) {
            New-Item -ItemType Directory -Path $scriptPath -Force | Out-Null
            Write-Host "Created directory: $scriptPath"
        }
    
        $computerName = $env:COMPUTERNAME
        $Filename = "IntuneWin32DeployerCustomlog"
        $logDir = Join-Path -Path $scriptPath -ChildPath "exports\Logs\$computerName"
        $logPath = Join-Path -Path $logDir -ChildPath "$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
            
        if (!(Test-Path $logPath)) {
            Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
            Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
            $createdLogDir = New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop
            Write-Host "Created log file at $logPath" -ForegroundColor Green
        }
            
        $logFile = Join-Path -Path $logPath -ChildPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null
    
        $CSVDir = Join-Path -Path $scriptPath -ChildPath "exports\CSV"
        $CSVFilePath = Join-Path -Path $CSVDir -ChildPath "$computerName"
            
        if (!(Test-Path $CSVFilePath)) {
            Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
            Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
            $createdCSVDir = New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop
            Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Green
        }
    
        return @{
            ScriptPath  = $scriptPath
            Filename    = $Filename
            LogPath     = $logPath
            LogFile     = $logFile
            CSVFilePath = $CSVFilePath
        }
    
    }
    catch {
        Write-Error "An error occurred while initializing script and logging: $_"
    }
}
$initializationInfo = Initialize-ScriptAndLogging
    
    
    
# Script Execution and Variable Assignment
# After the function Initialize-ScriptAndLogging is called, its return values (in the form of a hashtable) are stored in the variable $initializationInfo.
    
# Then, individual elements of this hashtable are extracted into separate variables for ease of use:
    
# $ScriptPath: The path of the script's main directory.
# $Filename: The base name used for log files.
# $logPath: The full path of the directory where logs are stored.
# $logFile: The full path of the transcript log file.
# $CSVFilePath: The path of the directory where CSV files are stored.
# This structure allows the script to have a clear organization regarding where logs and other files are stored, making it easier to manage and maintain, especially for logging purposes. It also encapsulates the setup logic in a function, making the main script cleaner and more focused on its primary tasks.
    
    
$ScriptPath = $initializationInfo['ScriptPath']
$Filename = $initializationInfo['Filename']
$logPath = $initializationInfo['LogPath']
$logFile = $initializationInfo['LogFile']
$CSVFilePath = $initializationInfo['CSVFilePath']
    
    
    
    
function AppendCSVLog {
    param (
        [string]$Message,
        [string]$CSVFilePath
           
    )
    
    $csvData = [PSCustomObject]@{
        TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        ComputerName = $env:COMPUTERNAME
        Message      = $Message
    }
    
    $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
}
    
    
    
function CreateEventSourceAndLog {
    param (
        [string]$LogName,
        [string]$EventSource
    )
    
    
    # Validate parameters
    if (-not $LogName) {
        Write-Warning "LogName is required."
        return
    }
    if (-not $EventSource) {
        Write-Warning "Source is required."
        return
    }
    
    # Function to create event log and source
    function CreateEventLogSource($logName, $EventSource) {
        try {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                New-EventLog -LogName $logName -Source $EventSource
            }
            else {
                [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $logName)
            }
            Write-Host "Event source '$EventSource' created in log '$logName'" -ForegroundColor Green
        }
        catch {
            Write-Warning "Error creating the event log. Make sure you run PowerShell as an Administrator."
        }
    }
    
    # Check if the event log exists
    if (-not (Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue)) {
        # CreateEventLogSource $LogName $EventSource
    }
    # Check if the event source exists
    elseif (-not ([System.Diagnostics.EventLog]::SourceExists($EventSource))) {
        # Unregister the source if it's registered with a different log
        $existingLogName = (Get-WinEvent -ListLog * | Where-Object { $_.LogName -contains $EventSource }).LogName
        if ($existingLogName -ne $LogName) {
            Remove-EventLog -Source $EventSource -ErrorAction SilentlyContinue
        }
        # CreateEventLogSource $LogName $EventSource
    }
    else {
        Write-Host "Event source '$EventSource' already exists in log '$LogName'" -ForegroundColor Yellow
    }
}
    
$LogName = (Get-Date -Format "HHmmss") + "_IntuneWin32DeployerCustomlog"
$EventSource = (Get-Date -Format "HHmmss") + "_IntuneWin32DeployerCustomlog"
    
# Call the Create-EventSourceAndLog function
CreateEventSourceAndLog -LogName $LogName -EventSource $EventSource
    
# Call the Write-CustomEventLog function with custom parameters and level
# Write-CustomEventLog -LogName $LogName -EventSource $EventSource -EventMessage "Outlook Signature Restore completed with warnings." -EventID 1001 -Level 'WARNING'
    
    
    
    
function Write-EventLogMessage {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
    
        [string]$LogName = 'IntuneWin32DeployerCustomlog',
        [string]$EventSource,
    
        [int]$EventID = 1000  # Default event ID
    )
    
    $ErrorActionPreference = 'SilentlyContinue'
    $hadError = $false
    
    try {
        if (-not $EventSource) {
            throw "EventSource is required."
        }
    
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell version is less than 6, use Write-EventLog
            Write-EventLog -LogName $logName -Source $EventSource -EntryType Information -EventId $EventID -Message $Message
        }
        else {
            # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $EventSource
            $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $EventID)
        }
    
        # Write-host "Event log entry created: $Message" 
    }
    catch {
        Write-host "Error creating event log entry: $_" 
        $hadError = $true
    }
    
    if (-not $hadError) {
        # Write-host "Event log message writing completed successfully."
    }
}
    
    
    
    
function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [switch]$UseModule = $false,
        [string]$Caller = (Get-PSCallStack)[0].Command
    )
    
    # Add timestamp, computer name, and log level to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Level] [$Caller] $Message"
    
    # Set foreground color based on log level
    switch ($Level) {
        'INFO' { $ForegroundColor = [ConsoleColor]::Green }
        'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
        'ERROR' { $ForegroundColor = [ConsoleColor]::Red }
    }
    
    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    # Write-output $formattedMessage
    Write-host $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    
    # Append to CSV file
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath
    
    # Write to event log (optional)
    # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level

    
    # Adjust this line in your script where you call the function
    # Write-EventLogMessage -LogName $LogName -EventSource $EventSource -Message $formattedMessage -EventID 1001
    
}
    
function Export-EventLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogName,
        [Parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    
    try {
        wevtutil epl $LogName $ExportPath
    
        if (Test-Path $ExportPath) {
            Write-EnhancedLog -Message "Event log '$LogName' exported to '$ExportPath'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
        else {
            Write-EnhancedLog -Message "Event log '$LogName' not exported: File does not exist at '$ExportPath'" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        }
    }
    catch {
        Write-EnhancedLog -Message "Error exporting event log '$LogName': $($_.Exception.Message)" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
    }
}
    
# # Example usage
# $LogName = 'IntuneWin32DeployerCustomlogLog'
# # $ExportPath = 'Path\to\your\exported\eventlog.evtx'
# $ExportPath = "C:\code\IntuneWin32DeployerCustomlog\exports\Logs\$logname.evtx"
# Export-EventLog -LogName $LogName -ExportPath $ExportPath
    
    
    
    
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################
    
    
    
Write-EnhancedLog -Message "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    
    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################










####################################################################################
#   Variables
####################################################################################
$global:version_iwd = "1.2.2"

# Basic Variables 
$global:ProgramPath = "$env:LOCALAPPDATA\Intune-Win32-Deployer"
$global:SettingsPath = $global:ProgramPath + '\ressources\settings.xml'
$global:ProgramIcon = $global:ProgramPath + '\ressources\Intune-Win32-Deployer.ico'
$global:Status = "ready"
$global:intunewinOnly = $false
# Colors
$global:Color_Button = "#0288d1"
$global:Color_ButtonHover = "#4fc3f7"
$global:Color_bg = "#121212"
$global:Color_warning = "#f44336"
$global:Color_error = "#ffa726"


# $CustomWin32AppName = "PRINT:003 - Uninstall - MX-3071 - SHARP - Concorde - CRM - 192.168.53.155 - Cert - PSADT"
$CustomWin32AppName = "PRINT:004 - MX-3071 - SHARP SHAW - 192.168.41.20 - Cert - PSADT"


####################################################################################
#   GUID
####################################################################################



function Add-GuidToPs1Files {
    param (
        [string]$AOscriptDirectory
    )

    # Validate the root script directory
    if (-Not (Test-Path -Path $AOscriptDirectory)) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): The specified script root directory does not exist: $AOscriptDirectory" -ForegroundColor Red
        return
    }

    # Define the target folder within the provided directory
    $targetFolder = Join-Path -Path $AOscriptDirectory -ChildPath "apps-winget\7zip.7zip"

    # Validate the target folder path
    if (-Not (Test-Path -Path $targetFolder)) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): The target folder does not exist: $targetFolder" -ForegroundColor Red
        return
    }

    # Generate a new GUID and timestamp outside the loop
    $AOguid = [guid]::NewGuid()
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $global:AOguidString = $AOguid.ToString("D").ToLower()

    # Find all .ps1 files in the target folder
    $ps1Files = Get-ChildItem -Path $targetFolder -Filter *.ps1 -Recurse

    if ($ps1Files.Count -eq 0) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): No PowerShell files (.ps1) found in $targetFolder" -ForegroundColor Yellow
        return
    }

    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Starting to modify files in $targetFolder" -ForegroundColor Cyan

    foreach ($file in $ps1Files) {
        try {
            # Read the current content of the file
            $content = Get-Content -Path $file.FullName -ErrorAction Stop

            # Check for and remove any existing tracking ID line
            $pattern = '^#Unique Tracking ID: .+'
            $content = $content | Where-Object { $_ -notmatch $pattern }

            # Define the new line to prepend to the file, using the same GUID and timestamp for each file
            $global:lineToAdd = "#Unique Tracking ID: $global:AOguidString, Timestamp: $timestamp"

            # Prepend the new line to the content
            $newContent = $global:lineToAdd, $content

            # Write the new content back to the file
            Set-Content -Path $file.FullName -Value $newContent -ErrorAction Stop

            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Modified file: $($file.FullName)" -ForegroundColor Green
        } catch {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Failed to modify file: $($file.FullName). Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Completed modifications. Global Tracking ID: $global:AOguidString" -ForegroundColor Cyan
}

# Example usage:
Add-GuidToPs1Files -AOscriptDirectory $AOscriptDirectory



####################################################################################
#   Functions
####################################################################################

function Check-Version {
    $version_github = (Invoke-webrequest -URI "https://raw.githubusercontent.com/FlorianSLZ/Intune-Win32-Deployer/main/source/ressources/version").Content
    if ([System.Version]$global:version_github -ge [System.Version]$version_iwd) {
        $updateYN = New-Object -ComObject Wscript.Shell
        if ($($updateYN.Popup("New version available: $version_github. Do you want to update?", 0, "Alert", 64 + 4)) -eq 6) {
            # Download latest version
            $GitHubRepo_url = "https://github.com/FlorianSLZ/Intune-Win32-Deployer/archive/refs/heads/main.zip"
            $GitHubRepo_name = "Intune-Win32-Deployer"
            $wc = New-Object net.webclient
            $wc.Downloadfile($GitHubRepo_url, "$Repo_Path\update.zip")
            Expand-Archive $Repo_Path\update.zip $Repo_Path\updatedata

            # call updater
            &"$Repo_Path\updatedata\Intune-Win32-Deployer-main\source\ressources\updater.ps1"

            # remove update data
            Remove-Item "$Repo_Path\updatedata" -Force -Recurse
            Remove-Item "$Repo_Path\update.zip" -Force -Recurse

        }
    }
}

function Read-AppRepo {
    $AppRepo = Import-CSV -Path $Repo_CSV_Path -Encoding UTF8 -Delimiter ";"
    return $AppRepo  

}

function Add-AppRepo ($App2Add) {
    $AppRepo = Read-AppRepo
    $AppRepo += $App2Add
    $AppRepo | Export-CSV -Path $Repo_CSV_Path -NoTypeInformation -Encoding UTF8 -Delimiter ";"
}

function SearchAdd-ChocoApp ($searchText) {
    $Chocos2add = choco search $searchText | Out-GridView -OutputMode Multiple -Title "Select Applications to add"
    foreach ($ChocoApp in $Chocos2add) {
        # parameter mapping
        $ChocoApp_ID = $($ChocoApp.split(' ')[0])
        $ChocoApp_new = New-Object PsObject -Property @{ id = "$ChocoApp_ID"; manager = "choco" }
        # add to CSV
        Add-AppRepo $ChocoApp_new
        # xy added, wanna deploy?
        $deployYN = New-Object -ComObject Wscript.Shell
        if ($($deployYN.Popup("Chocolatey App >$ChocoApp_ID< added. Do you want to create the intunewin?", 0, "Create App", 64 + 4)) -eq 6) {
            # Trigger creation process
            $Prg = Read-AppRepo | Where-Object { $_.id -eq "$ChocoApp_ID" } | Select-Object -first 1
            Create-Chocolatey4Dependency
            Create-ChocoWin32App $Prg
        }


    }

}

function SearchAdd-WinGetApp ($searchText) {

    $winget2add = winget search --id $searchText --exact --accept-source-agreements
    if ($winget2add -like "*$searchText*") {
        # parameter mapping
        $WingetApp_new = New-Object PsObject -Property @{ id = "$searchText"; manager = "winget" }
        # add to CSV
        Add-AppRepo $WingetApp_new
        # xy added, wanna deploy?
        $deployYN = New-Object -ComObject Wscript.Shell
        if ($($deployYN.Popup("Winget App >$searchText< added. Do you want to create the intunewin?", 0, "Create App", 64 + 4)) -eq 6) {
            # Trigger creation process
            $Prg = Read-AppRepo | Where-Object { $_.id -eq "$searchText" } | Select-Object -first 1
            Create-winget4Dependency
            Create-WingetWin32App $Prg
        }
    }
    else {
        Write-Error "ID not found!"
    }

}

function Create-WingetWin32App($Prg) {
    # Write-Host "Create win32 package for $($Prg.id) (Microsoft Package Manager)" -Foregroundcolor cyan
    Write-Host "Create win32 package for $CustomWin32AppName" -Foregroundcolor cyan

    # Set and create program folder
    $Prg_Path = "$Repo_winget\$($Prg.id)"
    New-Item $Prg_Path -type Directory -Force

    Write-EnhancedLog -Message "Set and create program folder - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # create install file
    # $(Get-Content "$Repo_Path\ressources\template\winget\install.ps1").replace("WINGETPROGRAMID","$($Prg.id)") | Out-File "$Prg_Path\install.ps1" -Encoding utf8

    # create uninstall file
    # $(Get-Content "$Repo_Path\ressources\template\winget\uninstall.ps1").replace("WINGETPROGRAMID","$($Prg.id)") | Out-File "$Prg_Path\uninstall.ps1" -Encoding utf8

    # create validation file
    # $(Get-Content "$Repo_Path\ressources\template\winget\check.ps1").replace("WINGETPROGRAMID","$($Prg.id)")  | Out-File "$Prg_Path\check.ps1" -Encoding utf8



    Write-EnhancedLog -Message "starting - check appliaction name and set if not present" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    # check appliaction name and set if not present
    if (!$Prg.name) {


        # Write-EnhancedLog -Message "starting - winget search" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        # $WingetDetails = $(winget search --id $($Prg.id) --exact)

        # Write-EnhancedLog -Message "winget search - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

        # $WingetDetails = '(' + $($WingetDetails -join '|') + ')'
        # $pos = $WingetDetails.IndexOf("-|")
        # $WingetDescriptionPlus = $WingetDetails.Substring($pos + 2)
        # $pos = $WingetDescriptionPlus.IndexOf(" $($Prg.id)")
        # $Prg.name = $WingetDescriptionPlus.Substring(0, $pos)
        $Prg.name = $CustomWin32AppName
    }

    Write-EnhancedLog -Message "check appliaction name and set if not present - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    

    # check appliaction description and set if not present
    if (!$Prg.Description) {
        $Prg.Description = "Installation via Windows Package Manager"
    }

    Write-EnhancedLog -Message "check appliaction description and set if not present - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # check appliaction InstallExperience and set if not present
    if (!$Prg.as) { $Prg.as = "System" }

    Write-EnhancedLog -Message "check appliaction InstallExperience and set if not present - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # check if for img
    if (Get-ChildItem $Prg_Path -Filter "$($Prg.id).png") {
        $Prg_img = "$Prg_Path\$($Prg.id).png"
    }
    else {
        $Prg_img = "$Repo_Path\ressources\template\winget\winget-managed.png"
    }

    Write-EnhancedLog -Message "check if for img - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    # Set Dependency if not defined
    # if(!$Prg.dependency){$Prg.dependency = "Windows Package Manager"}

    # Create intunewin

    Write-EnhancedLog -Message "Invoking Compile-Win32_intunewin" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    Compile-Win32_intunewin $Prg $Prg_Path $Prg_img
    Write-EnhancedLog -Message "Compile-Win32_intunewin was invoked" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}

function Create-ChocoWin32App($Prg) {
    Write-Host "Create win32 package for $($Prg.id) (Package Manager: Chocolatey)" -Foregroundcolor cyan

    # Set and create program folder
    $Prg_Path = "$Repo_choco\$($Prg.id)"
    New-Item $Prg_Path -type Directory -Force | Out-Null

    # create install file
    $(Get-Content "$Repo_Path\ressources\template\choco\install.ps1").replace("CHOCOPROGRAMID", "$($Prg.id)") | Out-File "$Prg_Path\install.ps1" -Encoding utf8

    # create param file
    if ($Prg.parameter) { New-Item -Path "$Prg_Path\parameter.txt" -ItemType "file" -Force -Value $Prg.parameter }

    # create uninstall file
    $(Get-Content "$Repo_Path\ressources\template\choco\uninstall.ps1").replace("CHOCOPROGRAMID", "$($Prg.id)") | Out-File "$Prg_Path\uninstall.ps1"  -Encoding utf8

    # create validation file
    $(Get-Content "$Repo_Path\ressources\template\choco\check.ps1").replace("CHOCOPROGRAMID", "$($Prg.id)")  | Out-File "$Prg_Path\check.ps1" -Encoding utf8

    # check appliaction name and set if not present
    if (!$Prg.name) {
        $ChocoDetails = '(' + $((choco search $Prg.id --by-id-only --exact -v) -join '|') + ')'
        $pos = $ChocoDetails.IndexOf("Title:")
        $ChocoDescriptionPlus = $ChocoDetails.Substring($pos + 7)
        $pos = $ChocoDescriptionPlus.IndexOf(" |")
        $Prg.name = $ChocoDescriptionPlus.Substring(0, $pos)
    }

    # check appliaction description and set if not present
    if (!$Prg.Description) {
        $ChocoDetails = '(' + $((choco search $Prg.id --by-id-only --exact -v) -join '|') + ')'
        $pos = $ChocoDetails.IndexOf("Description:")
        $ChocoDescriptionPlus = $ChocoDetails.Substring($pos + 13)
        $pos = $ChocoDescriptionPlus.IndexOf("|")
        $Prg.Description = $ChocoDescriptionPlus.Substring(0, $pos)
    }

    # check appliaction InstallExperience and set if not present
    if (!$Prg.as) { $Prg.as = "system" }

    # check for img
    if (Get-ChildItem $Prg_Path -Filter "$($Prg.id).png") {
        $Prg_img = "$Prg_Path\$($Prg.id).png"
    }
    else {
        $Prg_img = "$Repo_Path\ressources\template\choco\choco-managed.png"
    }

    # Set Dependency if not defined
    if (!$Prg.dependency) { $Prg.dependency = "Chocolatey" }

    # Create intunewin
    Compile-Win32_intunewin $Prg $Prg_Path $Prg_img
}

function Create-Chocolatey4Dependency {
    try {
        if ($($global:intunewinOnly) -eq $false) {
            $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant

            $App = @()
            $App += New-Object psobject -Property @{Name = "Chocolatey"; id = "Chocolatey"; Description = "Paketmanager"; manager = ""; install = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -command .\install.ps1"; uninstall = "no uninstall!"; as = "system"; publisher = ""; parameter = "" }

            $AppChocolatey = Get-IntuneWin32App | where { $_.DisplayName -eq $App.Name } | select displayName, id
            if (!$AppChocolatey) {
                Write-Host "Processing Chocolatey as prerequirement"
                Create-CustomWin32App $App
            }
        }
    }
    catch {
        Write-Host "Error adding dependency for $($App.Name)" -ForegroundColor Red
        $_
    }

}


function Create-winget4Dependency {
    try {
        if ($($global:intunewinOnly) -eq $false) {
            $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant

            $App = @()
            $App += New-Object psobject -Property @{Name = "Windows Package Manager"; id = "winget"; Description = "Windows Package Manager is a comprehensive package manager solution that consists of a command line tool and set of services for installing applications on Windows 10 and Windows 11."; manager = ""; install = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -command .\install.ps1"; uninstall = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\uninstall.ps1"; as = "system"; publisher = ""; parameter = "" }

            $AppOnline = Get-IntuneWin32App | where { $_.DisplayName -eq $App.Name } | select name, id
            if (!$AppOnline) {
                Write-Host "Processing Windows Package Manager as prerequirement"
                Create-CustomWin32App $App
            }
        }
    }
    catch {
        Write-Host "Error adding dependency for $($App.Name)" -ForegroundColor Red
        $_
    }

}

function CheckInstall-LocalChocolatey {
    # Check if chocolatey is installed
    $CheckChocolatey = C:\ProgramData\chocolatey\choco.exe list
    if (!$CheckChocolatey) {
        Write-Host "Instaling Chocolatey (on local machine)"
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
}

function Create-CustomWin32App($Prg) {
    Write-Host "Create win32 package for $($Prg.name) (custom, no Package Manager)" -Foregroundcolor cyan

    # check appliaction name and set if not present
    if (!$Prg.name) {
        $Prg.name = $Prg.id
    }

    # Set program folder
    $Prg_Path = "$Repo_custom\$($Prg.name)"

    # check for img
    if (Get-ChildItem $Prg_Path -Filter "$($Prg.id).png") {
        $Prg_img = "$Prg_Path\$($Prg.id).png"
    }
    else {
        if (Get-ChildItem $Prg_Path -Filter "$($Prg.name).png") {
            $Prg_img = "$Prg_Path\$($Prg.name).png"
        }
        else {
            $Prg_img = "$Repo_Path\ressources\template\custom\program.png"
        }
    }

    # Create intunewin
    Compile-Win32_intunewin $Prg $Prg_Path $Prg_img
}

function Compile-Win32_intunewin($Prg, $Prg_Path, $Prg_img) {
    # download newest IntuneWinAppUtil
    Invoke-WebRequest -Uri $IntuneWinAppUtil_online -OutFile "$Repo_Path\ressources\IntuneWinAppUtil.exe" -UseBasicParsing
    # create intunewin file
    Start-Process "$Repo_Path\ressources\IntuneWinAppUtil.exe" -Argument "-c ""$Prg_Path"" -s install.ps1 -o ""$Prg_Path"" -q" -Wait -WindowStyle hidden

    if ($($global:intunewinOnly) -eq $false) {
        # Upload app
        Upload-Win32App $Prg $Prg_Path $Prg_img
    }
    else {
        # Open file location / intunewin 
        Invoke-Item $Prg_Path
    }
}

function Upload-Win32App ($Prg, $Prg_Path, $Prg_img) {
    Write-Host "Uploading: $($Prg.name)" -Foregroundcolor cyan

    try {
        
        # # Graph Connect 
        # $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant


        # Define the parameters for non-interactive connection
        $connectionParams = @{
            clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
            tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"
            ClientSecret = "3WD8Q~TIlVDVzb1mx2Gv9m.is9AaE6C3D5PpucBZ"  # Replace with your actual Client Secret
        }

        # Call the Connect-MSIntuneGraph function with splatted parameters
        $Session = Connect-MSIntuneGraph @connectionParams


        # # Connect MGGraph if needed
        # if (($($global:SettingsVAR.AADgrp) -eq "True") -or ($($global:SettingsVAR.AADUninstallgrp) -eq "True")) {
        #     $MGSession = Connect-MgGraph -Scopes $global:scopes
        # }


        # $clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
        # $tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

        # $refreshToken = '0.AXgANoflv7PuJ0W3fMFdIaifE5Vemsw98_lFqUJOsdC1DpJ4AOA.AgABAAEAAAAmoFfGtYxvRrNriQdPKIZ-AgDs_wUA9P8JHLDLZbvx6evTZBj7o-7EwVbBG6pZXK4DLt0BFQUAi0sz-rWUme11jZj4tArzuWPwupsq3UXQOL7j_DEJFO28RaDRwYylFdBbmLRjoP0NW0EBUpk-_1E4yqlz7b5yT5XwVSOLvL2dBv19EZJzGzAn76KX6wTNbUCqWhjrs04J6VJrmBK1bUzjL2PdOtkddPxXFt7ZcTF4AEyDXXNuO8_ZCRmrkMcMgjCjsqYV5RSti6KNWur4H-1-eiOZXqwekzA-a1SGxcCEqRyggiFvtEXME5sXmQDCK2HfukJNwxrI6E_mu6g5xTH4lfM1UQz7Lly2m3Opclo-KQn_YGFLTRvOa1yqyzCzttZYYCBmaVm9IMleLjoVphJpEjXXwXrdbfmcBG37U4gWw6vAW7NO6TEdnRqzfpviSaa2IKYjuNXnK52N6HlB5B4c0ZEaNDsa2UDtNG64hwGZnR8yHMS9ZlaBttfrn3kXuoLd8l6T1ICVjEvH_vbHMthMJGsKzET1bMqkAo6pvtTK3Cwn2aO4CCePgnfgbbbrWzYx9t070arE_XgUfezok3EYMbMN51YBBjIc6kuZTp9_EtI4dqWiGLjsN8QEpRpzOxP3__fSM0JI27jcEYjrD5ZJmFEjwHsddTzUr5j9EZqJeUCfrUkKYb1jvYVjOvzAD9oWdFkwPsENI0DGcGdCcgUS22GgvZc6AF_XF_qb7OQ6e-hCDm7tb6yND0wmTMq4r2t1Zpp2NvTeZwfWK1cYLElVLkgL_x2BoifA6ZoioiIADGZAwrWYRQ'


        # Token endpoint
        # $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

        # Prepare the request body. Exclude 'client_secret' if your app is a public client.
        # $body = @{
        #     client_id     = $clientId
        #     grant_type    = "refresh_token"
        #     refresh_token = $refreshToken
        #     # Uncomment the next line if your application is a confidential client
        #     #client_secret = $clientSecret
        #     scope         = "https://graph.microsoft.com/.default"  # Adjust this scope according to your needs
        # }

        # Make the POST request
        # $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        # Output the new access token and refresh token
        # Write-Host "New Access Token: $($response.access_token)"
        # Some authorization servers might not return a new refresh token every time you refresh an access token
        # if ($response.refresh_token) {
            # Write-Host "New Refresh Token: $($response.refresh_token)" uncomment for debugging
        # }


        # $accessTokenString = $response.access_token

        # Assuming your access token is stored in a variable named $accessTokenString
        # Convert the plain string token to a SecureString
        # $secureAccessToken = $accessTokenString | ConvertTo-SecureString -AsPlainText -Force

        # Use the SecureString access token to connect
        # Connect-MgGraph -AccessToken $secureAccessToken

        # get .intunewin for Upload 
        $IntuneWinFile = "$Prg_Path\install.intunewin"

       

        ##################################################################################################################################
        ##################################################################################################################################
        #####################################################################Modify the following parameters##############################
        ##################################################################################################################################


        # read Displayname 
        $DisplayName = "$($Prg.Name)"


        # create detection rule
        if ($Prg.manager -eq "choco") { $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "C:\ProgramData\chocolatey\lib" -FileOrFolder $($Prg.id) -DetectionType "exists" }
        #elseif($Prg.manager -eq "winget"){}
        else {
            $DetectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile "$Prg_Path\check.ps1" -EnforceSignatureCheck $false -RunAs32Bit $false
        }
        

        # minimum requirements
        $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedWindowsRelease 1607

        # picture for win32 app (shown in company portal)
        $Icon = New-IntuneWin32AppIcon -FilePath $Prg_img

        # Install/uninstall commands
        $InstallCommandLine = "Deploy-Application.exe"
        # $InstallCommandLine = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1"
        # $InstallCommandLine = "ServiceUI.exe -process:explorer.exe Deploy-Application.exe"
        # $UninstallCommandLine = "ServiceUI.exe -process:explorer.exe Deploy-Application.exe -DeploymentType Uninstall"
        # $UninstallCommandLine = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\uninstall.ps1"
        $UninstallCommandLine = "Deploy-Application.exe -DeploymentType Uninstall"
        
        # Upload 
        # $upload = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description $($Prg.description) -Publisher $global:SettingsVAR.Publisher -InstallExperience $($Prg.as) -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Icon $Icon 
        


        # Updated hashtable with new parameters and placeholder values
        $IntuneAppParams = @{
            FilePath                 = $IntuneWinFile
            DisplayName              = $DisplayName
            # DisplayName               = "MX-4071 - SHARP Concord - 192.168.53.151"
            # Description               = $Prg.description
            # Description               = "MX-4071 - SHARP Concord - 192.168.53.151"
            Description              = $DisplayName
            Publisher                = $global:SettingsVAR.Publisher
            AppVersion               = "1.0.0"  # Placeholder value
            Developer                = "Abdullah Ollivierre"  # Placeholder value
            Owner                    = "Abdullah Ollivierre"  # Placeholder value
            # Notes                    = "#Unique Tracking ID 524d35b5-7811-464d-85ca-718a38c25a95"  # Placeholder value
            # Notes                    = "#Unique Tracking ID $global:AOguidString"  # Placeholder value
            Notes                    = "$global:lineToAdd"  # Placeholder value
            # InformationURL            = "https://placeholder.com/info"  # Placeholder value
            # PrivacyURL                = "https://placeholder.com/privacy"  # Placeholder value
            CompanyPortalFeaturedApp = $true  # Placeholder value (true or false)
            InstallCommandLine       = $InstallCommandLine
            UninstallCommandLine     = $UninstallCommandLine
            InstallExperience        = $Prg.as
            RestartBehavior          = "suppress"
            DetectionRule            = $DetectionRule
            RequirementRule          = $RequirementRule
            # AdditionalRequirementRule = @()  # Placeholder value, should be an array of OrderedDictionary objects
            # ReturnCode                = @()  # Placeholder value, should be an array of hash-tables
            Icon                     = $Icon
        }

        # Use splatting to pass the hashtable as parameters to the cmdlet
        # Upload 
        $upload = Add-IntuneWin32App @IntuneAppParams

        

        Write-Host "Upload completed: $($Prg.name)" -Foregroundcolor green
    }
    catch {
        Write-Host "Error application $($Prg.Name)" -ForegroundColor Red
        $_
    }
    # Sleep to prevent block from azure on a mass upload
    Start-sleep -s 10

    # try{
    #     # Check dependency
    #     if($Prg.dependency){
    #         Write-Host "  Processing dependency $($Prg.dependency) to $($Prg.Name)" -ForegroundColor Cyan
    #         $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant
    #         $UploadedApp = Get-IntuneWin32App | where {$_.DisplayName -eq $Prg.Name} | select name, id
    #         $DependendProgram = Get-IntuneWin32App | where {$_.DisplayName -eq $Prg.dependency} | select name, id
    #         if(!$DependendProgram){
    #             Write-Host "    dependent program $($Prg.dependency) is not present in the MEM enviroment, please create/upload first." -ForegroundColor Orange
    #         }
    #         $DependendProgram = Get-IntuneWin32App | where {$_.DisplayName -eq $Prg.dependency} | select name, id
    #         $Dependency = New-IntuneWin32AppDependency -id $DependendProgram.id -DependencyType AutoInstall
    #         $UploadProcess = Add-IntuneWin32AppDependency -id $UploadedApp.id -Dependency $Dependency
    #         Write-Host "  Added dependency $($Prg.dependency) to $($Prg.Name)" -ForegroundColor Cyan
    #     }
    # }catch{
    #     Write-Host "Error adding dependency for $($Prg.Name)" -ForegroundColor Red
    #     $_
    # }

    # if ($($global:SettingsVAR.AADgrp) -eq "True") { Create-AADGroup $Prg }
    # if ($($global:SettingsVAR.AADuninstallgrp) -eq "True") { Create-AADUninstallGroup $Prg }
    # if ($Prg.manager -like "*winget*") {
    #     if ($($global:SettingsVAR.PRupdater) -eq "True") { Create-PRUpdater $Prg }
    # }

}


function Import-FromCatalog {
    # $Prg_selection = Read-AppRepo | Out-GridView -OutputMode Multiple -Title "Select Applications to create and upload"
    # $Prg_selection = Read-AppRepo
    $Prg_selection = Read-AppRepo
    # if ($global:intunewinOnly -eq $false) { $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant }
    # if ($global:intunewinOnly -eq $false) { 
        
        
        
        
        
        
        
        
    #     $clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
    #     $tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

    #     $refreshToken = '0.AXgANoflv7PuJ0W3fMFdIaifE5Vemsw98_lFqUJOsdC1DpJ4AOA.AgABAAEAAAAmoFfGtYxvRrNriQdPKIZ-AgDs_wUA9P8JHLDLZbvx6evTZBj7o-7EwVbBG6pZXK4DLt0BFQUAi0sz-rWUme11jZj4tArzuWPwupsq3UXQOL7j_DEJFO28RaDRwYylFdBbmLRjoP0NW0EBUpk-_1E4yqlz7b5yT5XwVSOLvL2dBv19EZJzGzAn76KX6wTNbUCqWhjrs04J6VJrmBK1bUzjL2PdOtkddPxXFt7ZcTF4AEyDXXNuO8_ZCRmrkMcMgjCjsqYV5RSti6KNWur4H-1-eiOZXqwekzA-a1SGxcCEqRyggiFvtEXME5sXmQDCK2HfukJNwxrI6E_mu6g5xTH4lfM1UQz7Lly2m3Opclo-KQn_YGFLTRvOa1yqyzCzttZYYCBmaVm9IMleLjoVphJpEjXXwXrdbfmcBG37U4gWw6vAW7NO6TEdnRqzfpviSaa2IKYjuNXnK52N6HlB5B4c0ZEaNDsa2UDtNG64hwGZnR8yHMS9ZlaBttfrn3kXuoLd8l6T1ICVjEvH_vbHMthMJGsKzET1bMqkAo6pvtTK3Cwn2aO4CCePgnfgbbbrWzYx9t070arE_XgUfezok3EYMbMN51YBBjIc6kuZTp9_EtI4dqWiGLjsN8QEpRpzOxP3__fSM0JI27jcEYjrD5ZJmFEjwHsddTzUr5j9EZqJeUCfrUkKYb1jvYVjOvzAD9oWdFkwPsENI0DGcGdCcgUS22GgvZc6AF_XF_qb7OQ6e-hCDm7tb6yND0wmTMq4r2t1Zpp2NvTeZwfWK1cYLElVLkgL_x2BoifA6ZoioiIADGZAwrWYRQ'


    #     # Token endpoint
    #     $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

    #     # Prepare the request body. Exclude 'client_secret' if your app is a public client.
    #     $body = @{
    #         client_id     = $clientId
    #         grant_type    = "refresh_token"
    #         refresh_token = $refreshToken
    #         # Uncomment the next line if your application is a confidential client
    #         #client_secret = $clientSecret
    #         scope         = "https://graph.microsoft.com/.default"  # Adjust this scope according to your needs
    #     }

    #     # Make the POST request
    #     $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

    #     # Output the new access token and refresh token
    #     # Write-Host "New Access Token: $($response.access_token)"
    #     # Some authorization servers might not return a new refresh token every time you refresh an access token
    #     if ($response.refresh_token) {
    #         # Write-Host "New Refresh Token: $($response.refresh_token)" uncomment for debugging
    #     }


    #     $accessTokenString = $response.access_token

    #     # Assuming your access token is stored in a variable named $accessTokenString
    #     # Convert the plain string token to a SecureString
    #     $secureAccessToken = $accessTokenString | ConvertTo-SecureString -AsPlainText -Force

    #     # Use the SecureString access token to connect
    #     # Connect-MgGraph -AccessToken $secureAccessToken

    #     $Session = Connect-MgGraph -AccessToken $secureAccessToken
        
        
        
        
    #     # $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant
    
    # }
    # if ($Prg_selection.manager -like "*choco*") { CheckInstall-LocalChocolatey }
    # if ($Prg_selection.manager -like "*choco*") { Create-Chocolatey4Dependency }
    # if ($Prg_selection.manager -like "*winget*") { Create-winget4Dependency }

    # foreach ($Prg in $Prg_selection) {
    #     if ($Prg.manager -eq "choco") { Create-ChocoWin32App $Prg }
    #     elseif ($Prg.manager -eq "winget") { Create-WingetWin32App $Prg }
    #     else { Create-CustomWin32App $Prg }
    # }

    # $Prg = "7zip.7zip"
    # Create-CustomWin32App $Prg 

    foreach ($Prg in $Prg_selection) {
        # if ($Prg.manager -eq "choco") { Create-ChocoWin32App $Prg }
        # elseif ($Prg.manager -eq "winget") { Create-WingetWin32App $Prg }
        # else { Create-CustomWin32App $Prg }


        Create-WingetWin32App $Prg

        # Create-CustomWin32App $Prg
    }

}

function Create-AADGroup ($Prg) {
    # Connect AAD if not connected
    $MGSession = Connect-MgGraph -Scopes $global:scopes

    # Create Group
    $grpname = "$($global:SettingsVAR.AADgrpPrefix )$($Prg.id)"
    if (!$(Get-MgGroup -Filter "DisplayName eq '$grpname'")) {
        Write-Host "  Create AAD group for assigment:  $grpname" -Foregroundcolor cyan
        $GrpObj = New-MgGroup -DisplayName "$grpname" -Description "App assigment: $($Prg.id) $($Prg.manager)" -MailEnabled:$False  -MailNickName $grpname -SecurityEnabled
    }
    else { $GrpObj = Get-MgGroup -Filter "DisplayName eq '$grpname'" }

    # Add App Assigment
    Write-Host "  Assign Group > $grpname <  to  > $($Prg.Name) <" -Foregroundcolor cyan
    $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant
    $Win32App = Get-IntuneWin32App -DisplayName "$($Prg.Name)"
    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $GrpObj.id -Intent "required" -Notification "showAll"
}


function Create-AADUninstallGroup ($Prg) {
    # Connect AAD if not connected
    $MGSession = Connect-MgGraph -Scopes $global:scopes

    # Create Group
    $grpUNname = "$($global:SettingsVAR.AADgrpPrefix )$($Prg.id)_uninstall"
    if (!$(Get-MgGroup -Filter "DisplayName eq '$grpUNname'")) {
        Write-Host "  Create AAD group for uninstall assigment:  $grpUNname" -Foregroundcolor cyan
        $GrpObj = New-MgGroup -DisplayName "$grpUNname" -Description "App uninstall assigment: $($Prg.id) $($Prg.manager)" -MailEnabled:$False  -MailNickName $grpUNname -SecurityEnabled
    }
    else { $GrpObj = Get-MgGroup -Filter "DisplayName eq '$grpUNname'" }

    # Add App Assigment
    Write-Host "  Assign Uninstaller Group > $grpUNname <  to  > $($Prg.Name) <" -Foregroundcolor cyan
    $Session = Connect-MSIntuneGraph -TenantID $SettingsVAR.Tenant
    $Win32App = Get-IntuneWin32App -DisplayName "$($Prg.Name)"
    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $GrpObj.id -Intent "uninstall" -Notification "showReboot"
}

function Create-PRUpdater ($Prg) {
   
    Write-Host "Creating Proactive Remediation: $PAR_name" -ForegroundColor Cyan

    $Publisher = $global:SettingsVAR.Publisher
    $PAR_name = "winget upgrade - $($Prg.Name)"
    $winget_id = $($Prg.id)
    $PAR_description = "Created via Intune Win32 Deployer"
    $PAR_RunAs = "system"
    $PAR_Scheduler = "Daily"
    $PAR_Frequency = "1"
    $PAR_StartTime = "01:00"
    $PAR_RunAs32 = $false
    $PAR_AADGroup = "$($global:SettingsVAR.AADgrpPrefix )$($Prg.id)"
    $PAR_detection_path = "$Repo_Path\Proactive Remediations\$PAR_name\detection-winget-upgrade.ps1"
    $PAR_remediation_path = "$Repo_Path\Proactive Remediations\$PAR_name\remediation-winget-upgrade.ps1"

    #   Create Detection and Remediation Script
    $script_detection = @'
    $app_2upgrade = "WINGETPROGRAMID"

    $Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\winget.exe")

    if ($(&$winget upgrade) -like "* $app_2upgrade *") {
        Write-Host "Upgrade available for: $app_2upgrade"
        exit 1 # upgrade available, remediation needed
    }
    else {
            Write-Host "No Upgrade available"
            exit 0 # no upgared, no action needed
    }
'@

    $script_remediation = @'
    $app_2upgrade = "WINGETPROGRAMID"

    try{
        $Winget = Get-ChildItem -Path (Join-Path -Path (Join-Path -Path $env:ProgramFiles -ChildPath "WindowsApps") -ChildPath "Microsoft.DesktopAppInstaller*_x64*\winget.exe")

        # upgrade command
        &$winget upgrade --exact $app_2upgrade --silent --force --accept-package-agreements --accept-source-agreements
        exit 0

    }catch{
        Write-Error "Error while installing upgarde for: $app_2upgrade"
        exit 1
    }

'@

    # Create and save
    New-Item -Path "$Repo_Path\Proactive Remediations\$PAR_name" -Type Directory -Force
    $PAR_detection = $script_detection.replace("WINGETPROGRAMID", "$winget_id") 
    $PAR_detection | Out-File (New-Item $PAR_detection_path -Type File -Force) -Encoding utf8
    $PAR_remediation = $script_remediation.replace("WINGETPROGRAMID", "$winget_id") 
    $PAR_remediation | Out-File (New-Item $PAR_remediation_path -Type File -Force) -Encoding utf8



    #   Create the Proactive remediation script package
    $params = @{
        DisplayName              = $PAR_name
        Description              = $PAR_description
        Publisher                = $Publisher
        PAR_RunAs32Bit           = $PAR_RunAs32
        RunAsAccount             = $PAR_RunAs
        EnforceSignatureCheck    = $false
        DetectionScriptContent   = [System.Text.Encoding]::ASCII.GetBytes($PAR_detection)
        RemediationScriptContent = [System.Text.Encoding]::ASCII.GetBytes($PAR_remediation)
        RoleScopeTagIds          = @(
            "0"
        )
    }
    Write-Host " "
    Connect-MSGraph

    $graphApiVersion = "beta"
    $Resource = "deviceManagement/deviceHealthScripts"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

    try {
        $proactive = Invoke-MSGraphRequest -Url $uri -HttpMethod Post -Content $params
        Write-Host "Proactive Remediation Created" -ForegroundColor Green
    }
    catch {
        Write-Error $_.Exception
    }

    Connect-MgGraph

    #   Get Group ID
    $AADGroupID = (Get-MgGroup -Filter "DisplayName eq '$PAR_AADGroup'").id
    if ($AADGroupID) {
        ##Set the JSON
        if ($PAR_Scheduler -eq "Hourly") {
            Write-Host "  Assigning Hourly Schedule running every $PAR_Frequency hours"
            $params = @{
                DeviceHealthScriptAssignments = @(
                    @{
                        Target               = @{
                            "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                            GroupId       = $AADGroupID
                        }
                        RunRemediationScript = $true
                        RunSchedule          = @{
                            "@odata.type" = "#microsoft.graph.deviceHealthScriptHourlySchedule"
                            Interval      = $PAR_Frequency
                        }
                    }
                )
            }
        }
        else {
            Write-Host "  Assigning Daily Schedule running at $PAR_StartTime each $PAR_Frequency days"
            $params = @{
                DeviceHealthScriptAssignments = @(
                    @{
                        Target               = @{
                            "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                            GroupId       = $AADGroupID
                        }
                        RunRemediationScript = $true
                        RunSchedule          = @{
                            "@odata.type" = "#microsoft.graph.deviceHealthScriptDailySchedule"
                            Interval      = $PAR_Frequency
                            Time          = $PAR_StartTime
                            UseUtc        = $false
                        }
                    }
                )
            }
        }

        $remediationID = $proactive.ID


        $graphApiVersion = "beta"
        $Resource = "deviceManagement/deviceHealthScripts"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$remediationID/assign"

        try {
            $proactive = Invoke-MSGraphRequest -Url $uri -HttpMethod Post -Content $params
        }
        catch {
            Write-Error $_.Exception 
            
        }
    }
    else {
        Write-Host "Group $PAR_AADGroup not found, PAR createt but not assigned" -ForegroundColor Yellow
    }

}

####################################################################################
#   Functions - UI
####################################################################################
Function Restart-MainUI {
    try {
        $MainUI.Close()
        $MainUI.Dispose()
    
        Start-MainUI

    }
    catch {
        try { Start-MainUI }catch { $_ }
    }
}

function Status-Wrapper ($function2call) {
    $global:Status = "working..."
    $Label_Status.Text = "Status: $($global:Status)"
    $Label_Status.ForeColor = "#ff9900"
    $MainUI.Controls.Add($Label_Status)
    Invoke-Expression $function2call
    $global:Status = "ready"
    $Label_Status.Text = "Status: $($global:Status)"
    $Label_Status.ForeColor = "#009933"
    $MainUI.Controls.Add($Label_Status)
    Write-Host "Done. Ready for next task. " -BackgroundColor Blue
    Write-Host " "
}

# Einlesen der Initial Variabeln
Function Get-SettingVariables() {
    $global:SettingsVAR = Import-Clixml -Path $global:SettingsPath
    Open-Settings
} 

Function Set-SettingVariables($SettingsCol) {
    Export-Clixml -Path $global:SettingsPath -InputObject $SettingsCol -Force
    $global:SettingsVAR = Import-Clixml -Path $global:SettingsPath
    Restart-MainUI
}

Function Load-SettingVariables {
    $global:SettingsVAR = Import-Clixml -Path $global:SettingsPath
    if (!$($SettingsVAR.Tenant) -or ($SettingsVAR.Tenant -like "xxx.*") ) { Get-SettingVariables }

    Restart-MainUI
    
}

function Open-Settings {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    
    # Set the size of your form
    $form_Settings = New-Object System.Windows.Forms.Form
    $form_Settings.width = 400
    $form_Settings.height = 350
    $form_Settings.Text = "Settings"
    $form_Settings.Backcolor = "#FFFFFF"
    $form_Settings.Icon = $global:ProgramIcon
    $form_Settings.StartPosition = "CenterScreen"

    # label tenant name
    $Label_tenant = New-Object System.Windows.Forms.Label
    $Label_tenant.Location = new-object System.Drawing.Size(30, 10)
    $Label_tenant.Size = New-Object System.Drawing.Size(150, 20)
    $Label_tenant.Text = "Tenant Name"
    $form_Settings.Controls.Add($Label_tenant)

    # box tenant name
    $Box_tenant = New-Object System.Windows.Forms.TextBox
    $Box_tenant.Location = new-object System.Drawing.Size(200, 10)
    $Box_tenant.Size = New-Object System.Drawing.Size(150, 20)
    $Box_tenant.Text = $global:SettingsVAR.Tenant
    $form_Settings.Controls.Add($Box_tenant)

    # label publisher 
    $Label_publisher = New-Object System.Windows.Forms.Label
    $Label_publisher.Location = new-object System.Drawing.Size(30, 40)
    $Label_publisher.Size = New-Object System.Drawing.Size(150, 20)
    $Label_publisher.Text = "Publisher"
    $form_Settings.Controls.Add($Label_publisher)

    # box publisher 
    $Box_publisher = New-Object System.Windows.Forms.TextBox
    $Box_publisher.Location = new-object System.Drawing.Size(200, 40)
    $Box_publisher.Size = New-Object System.Drawing.Size(150, 20)
    $Box_publisher.Text = $global:SettingsVAR.Publisher
    $form_Settings.Controls.Add($Box_publisher)

    # label group prefix
    $Label_grpPrefix = New-Object System.Windows.Forms.Label
    $Label_grpPrefix.Location = new-object System.Drawing.Size(30, 70)
    $Label_grpPrefix.Size = New-Object System.Drawing.Size(150, 20)
    $Label_grpPrefix.Text = "AAD Group Prefix"
    $form_Settings.Controls.Add($Label_grpPrefix)

    # box group prefix
    $Box_grpPrefix = New-Object System.Windows.Forms.TextBox
    $Box_grpPrefix.Location = new-object System.Drawing.Size(200, 70)
    $Box_grpPrefix.Size = New-Object System.Drawing.Size(150, 20)
    $Box_grpPrefix.Text = $global:SettingsVAR.AADgrpPrefix
    $form_Settings.Controls.Add($Box_grpPrefix)
    
    # AAD install group checkbox 
    $checkbox_grp = new-object System.Windows.Forms.checkbox
    $checkbox_grp.Location = new-object System.Drawing.Size(30, 130)
    $checkbox_grp.Size = new-object System.Drawing.Size(250, 20)
    $checkbox_grp.Text = "Creat/Assign group per app"
    $checkbox_grp.Checked = [System.Convert]::ToBoolean($global:SettingsVAR.AADgrp)
    $form_Settings.Controls.Add($checkbox_grp)

    # AAD UNinstall group checkbox 
    $checkbox_uninstallgrp = new-object System.Windows.Forms.checkbox
    $checkbox_uninstallgrp.Location = new-object System.Drawing.Size(30, 170)
    $checkbox_uninstallgrp.Size = new-object System.Drawing.Size(250, 20)
    $checkbox_uninstallgrp.Text = "Creat/Assign uninstall group per app"
    $checkbox_uninstallgrp.Checked = [System.Convert]::ToBoolean($global:SettingsVAR.AADuninstallgrp)
    $form_Settings.Controls.Add($checkbox_uninstallgrp)

    # proactive remediations checkbox 
    $checkbox_PR = new-object System.Windows.Forms.checkbox
    $checkbox_PR.Location = new-object System.Drawing.Size(30, 210)
    $checkbox_PR.Size = new-object System.Drawing.Size(250, 20)
    $checkbox_PR.Text = "Create PR per app"
    $checkbox_PR.Checked = [System.Convert]::ToBoolean($global:SettingsVAR.PRupdater)
    $form_Settings.Controls.Add($checkbox_PR)  
 
    # OK button
    $OKButton = new-object System.Windows.Forms.Button
    $OKButton.Location = new-object System.Drawing.Size(30, 250)
    $OKButton.Size = new-object System.Drawing.Size(100, 40)
    $OKButton.Text = "OK"
    $OKButton.Add_Click({
            $global:SettingsVAR.AADgrp = $checkbox_grp.Checked
            $global:SettingsVAR.AADuninstallgrp = $checkbox_uninstallgrp.Checked
            $global:SettingsVAR.PRupdater = $checkbox_PR.Checked
            $global:SettingsVAR.AADgrpPrefix = $Box_grpPrefix.Text
            $global:SettingsVAR.Publisher = $Box_publisher.Text
            $global:SettingsVAR.Tenant = $Box_tenant.Text
            $form_Settings.Close()
            Set-SettingVariables $global:SettingsVAR
        
        })
    $form_Settings.Controls.Add($OKButton)
    
    # Activate the form
    $form_Settings.Add_Shown({ $form_Settings.Activate() })
    [void] $form_Settings.ShowDialog() 
}

function SearchForm-AddApp ($title, $description, $onlinesearch_text, $onlinesearch_url) {
    $form_AddApp = New-Object System.Windows.Forms.Form
    $form_AddApp.Text = $title
    $form_AddApp.Size = New-Object System.Drawing.Size(300, 200)
    $form_AddApp.Backcolor = "#FFFFFF"
    $form_AddApp.Icon = $global:ProgramIcon
    $form_AddApp.StartPosition = 'CenterScreen'

    $okButton_AddApp = New-Object System.Windows.Forms.Button
    $okButton_AddApp.Location = New-Object System.Drawing.Point(75, 120)
    $okButton_AddApp.Size = New-Object System.Drawing.Size(75, 23)
    $okButton_AddApp.Text = 'OK'
    $okButton_AddApp.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form_AddApp.AcceptButton = $okButton_AddApp
    $form_AddApp.Controls.Add($okButton_AddApp)

    $label_AddApp = New-Object System.Windows.Forms.Label
    $label_AddApp.Location = New-Object System.Drawing.Point(10, 20)
    $label_AddApp.Size = New-Object System.Drawing.Size(280, 20)
    $label_AddApp.Text = $description
    $form_AddApp.Controls.Add($label_AddApp)

    $textBox_AddApp = New-Object System.Windows.Forms.TextBox
    $textBox_AddApp.Location = New-Object System.Drawing.Point(10, 40)
    $textBox_AddApp.Size = New-Object System.Drawing.Size(260, 20)
    $form_AddApp.Controls.Add($textBox_AddApp)

    # Button "Find winget apps"
    $Button_SearchID = New-Object System.Windows.Forms.Button
    $Button_SearchID.Location = New-Object System.Drawing.Size(10, 80)
    $Button_SearchID.Size = New-Object System.Drawing.Size(260, 20)
    $Button_SearchID.Text = $onlinesearch_text
    $Button_SearchID.Name = $onlinesearch_text
    $Button_SearchID.backcolor = $Color_Button
    $Button_SearchID.Add_MouseHover( { $Button_SearchID.backcolor = $Color_ButtonHover })
    $Button_SearchID.Add_MouseLeave( { $Button_SearchID.backcolor = $Color_Button })
    $Button_SearchID.Add_Click( { Start-Process $onlinesearch_url } )
    $form_AddApp.Controls.Add($Button_SearchID)
    

    $form_AddApp.Topmost = $true

    $form_AddApp.Add_Shown({ $textBox_AddApp.Select() })
    $result = $form_AddApp.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        if ($title -like "*winget*") { SearchAdd-wingetApp $textBox_AddApp.Text }
        if ($title -like "*Chocolatey*") { SearchAdd-ChocoApp $textBox_AddApp.Text }

    }
}

function Start-MainUI {

    # Color - variable
    if ($global:intunewinOnly -eq $true) { $Button_intunewin_color = "#EAB676" }else { $Button_intunewin_color = "#A5A5A5" }
    
    # Main window
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $MainUI = New-Object System.Windows.Forms.Form
    $MainUI.Backcolor = $Color_bg
    $MainUI.StartPosition = "CenterScreen"
    $MainUI.Size = New-Object System.Drawing.Size(800, 400)
    $MainUI.Text = "Intune Win32 Deployer"
    $MainUI.Icon = $global:ProgramIcon

    # Button "Deploy from personal Catalog"
    $Button_Deploy = New-Object System.Windows.Forms.Button
    $Button_Deploy.Location = New-Object System.Drawing.Size(30, 30)
    $Button_Deploy.Size = New-Object System.Drawing.Size(200, 30)
    $Button_Deploy.Text = "Deploy from personal Catalog"
    $Button_Deploy.Name = "Deploy from personal Catalog"
    $Button_Deploy.backcolor = $Color_Button
    $Button_Deploy.Add_MouseHover( { $Button_Deploy.backcolor = $Color_ButtonHover })
    $Button_Deploy.Add_MouseLeave( { $Button_Deploy.backcolor = $Color_Button })
    $Button_Deploy.Add_Click( { Status-Wrapper "Import-FromCatalog" })
    $MainUI.Controls.Add($Button_Deploy)

    # Button "view personal Catalog"
    $Button_viewCatalog = New-Object System.Windows.Forms.Button
    $Button_viewCatalog.Location = New-Object System.Drawing.Size(240, 30)
    $Button_viewCatalog.Size = New-Object System.Drawing.Size(200, 30)
    $Button_viewCatalog.Text = "View App Catalog"
    $Button_viewCatalog.Name = "View App Catalog"
    $Button_viewCatalog.backcolor = $Color_Button
    $Button_viewCatalog.Add_MouseHover( { $Button_viewCatalog.backcolor = $Color_ButtonHover })
    $Button_viewCatalog.Add_MouseLeave( { $Button_viewCatalog.backcolor = $Color_Button })
    $Button_viewCatalog.Add_Click( { Status-Wrapper "Read-AppRepo | out-gridview" })
    $MainUI.Controls.Add($Button_viewCatalog)

    # Button "Add Chocolatey App"
    $Button_AddChoco = New-Object System.Windows.Forms.Button
    $Button_AddChoco.Location = New-Object System.Drawing.Size(30, 70)
    $Button_AddChoco.Size = New-Object System.Drawing.Size(200, 30)
    $Button_AddChoco.Text = "Add Chocolatey App"
    $Button_AddChoco.Name = "Add Chocolatey App"
    $Button_AddChoco.backcolor = $Color_Button
    $Button_AddChoco.Add_MouseHover( { $Button_AddChoco.backcolor = $Color_ButtonHover })
    $Button_AddChoco.Add_MouseLeave( { $Button_AddChoco.backcolor = $Color_Button })
    # $Button_AddChoco.Add_Click( { Status-Wrapper 'SearchForm-AddApp "Add Chocolatey App" "Type in search string" "Find packages / id online" "https://community.chocolatey.org/packages"' })
    $MainUI.Controls.Add($Button_AddChoco)

    # Button "Add winget App"
    $Button_Addwinget = New-Object System.Windows.Forms.Button
    $Button_Addwinget.Location = New-Object System.Drawing.Size(30, 110)
    $Button_Addwinget.Size = New-Object System.Drawing.Size(200, 30)
    $Button_Addwinget.Text = "Add winget App"
    $Button_Addwinget.Name = "Add winget App"
    $Button_Addwinget.backcolor = $Color_Button
    $Button_Addwinget.Add_MouseHover( { $Button_Addwinget.backcolor = $Color_ButtonHover })
    $Button_Addwinget.Add_MouseLeave( { $Button_Addwinget.backcolor = $Color_Button })
    # $Button_Addwinget.Add_Click( { Status-Wrapper 'SearchForm-AddApp "Add winget App" "Type in exact winget ID" "Find ID online" "https://winget.run"' } )
    $MainUI.Controls.Add($Button_Addwinget)

    # Info Tenant
    $Label_Tenant = New-Object System.Windows.Forms.Label
    $Label_Tenant.Location = New-Object System.Drawing.Size(30, 200)
    $Label_Tenant.Size = New-Object System.Drawing.Size(200, 30)
    $Label_Tenant.Text = "Tenant: $($global:SettingsVAR.Tenant)"
    $Label_Tenant.ForeColor = "#FFFFFF"
    $MainUI.Controls.Add($Label_Tenant)

    # Info Publisher
    $Label_Publisher = New-Object System.Windows.Forms.Label
    $Label_Publisher.Location = New-Object System.Drawing.Size(30, 230)
    $Label_Publisher.Size = New-Object System.Drawing.Size(200, 30)
    $Label_Publisher.Text = "Publisher: $($global:SettingsVAR.Publisher)"
    $Label_Publisher.ForeColor = "#FFFFFF"
    $MainUI.Controls.Add($Label_Publisher)

    # Info Status
    $Label_Status = New-Object System.Windows.Forms.Label
    $Label_Status.Location = New-Object System.Drawing.Size(500, 30)
    $Label_Status.Size = New-Object System.Drawing.Size(200, 30)
    $Label_Status.Text = "Status: $($global:Status)"
    $Label_Status.ForeColor = "#009933"
    $MainUI.Controls.Add($Label_Status)

    # Info Version
    $Label_Version = New-Object System.Windows.Forms.Label
    $Label_Version.Location = New-Object System.Drawing.Size(500, 300)
    $Label_Version.Size = New-Object System.Drawing.Size(200, 30)
    $Label_Version.Text = "Version $($global:version_iwd)"
    $Label_Version.ForeColor = "#555555"
    $MainUI.Controls.Add($Label_Version)

    # Button "Settings"
    $Button_Settings = New-Object System.Windows.Forms.Button
    $Button_Settings.Location = New-Object System.Drawing.Size(30, 260)
    $Button_Settings.Size = New-Object System.Drawing.Size(200, 30)
    $Button_Settings.Text = "Settings"
    $Button_Settings.Name = "Settings"
    $Button_Settings.backcolor = $Color_Button
    $Button_Settings.Add_MouseHover( { $Button_Settings.backcolor = $Color_ButtonHover })
    $Button_Settings.Add_MouseLeave( { $Button_Settings.backcolor = $Color_Button })
    $Button_Settings.Add_Click( { Open-Settings })
    $MainUI.Controls.Add($Button_Settings)

    # Button "only intunewin"
    $Button_intunewin = New-Object System.Windows.Forms.Button
    $Button_intunewin.Location = New-Object System.Drawing.Size(250, 260)
    $Button_intunewin.Size = New-Object System.Drawing.Size(200, 30)
    $Button_intunewin.Text = "only create intunewin"
    $Button_intunewin.Name = "only create intunewin"
    $Button_intunewin.backcolor = $Button_intunewin_color
    $Button_intunewin.Add_MouseHover( { $Button_intunewin.backcolor = $Color_ButtonHover })
    $Button_intunewin.Add_MouseLeave( { $Button_intunewin.backcolor = $Button_intunewin_color })
    $Button_intunewin.Add_Click( {
            if ($global:intunewinOnly -eq $true) { $global:intunewinOnly = $false }else { $global:intunewinOnly = $true }
            Restart-MainUI
        })
    $MainUI.Controls.Add($Button_intunewin) 

    # Button "Close"
    $Button_Close = New-Object System.Windows.Forms.Button
    $Button_Close.Location = New-Object System.Drawing.Size(30, 300)
    $Button_Close.Size = New-Object System.Drawing.Size(200, 30)
    $Button_Close.Text = "Close"
    $Button_Close.Name = "Close"
    $Button_Close.DialogResult = "Cancel"
    $Button_Close.backcolor = $Color_Button
    $Button_Close.Add_MouseHover( { $Button_Close.backcolor = $Color_ButtonHover })
    $Button_Close.Add_MouseLeave( { $Button_Close.backcolor = $Color_Button })
    $Button_Close.Add_Click( { $MainUI.Close() })
    $MainUI.Controls.Add($Button_Close)
    # show window
    [void] $MainUI.ShowDialog()

}

####################################################################################
#   Modules
####################################################################################
Import-Module "MSAL.PS"
Import-Module "IntuneWin32App"
Import-Module "Microsoft.Graph.Groups"
$global:scopes = @(
    "Group.ReadWrite.All"
)


####################################################################################
#   GO!
####################################################################################
Load-SettingVariables


stop-transcript