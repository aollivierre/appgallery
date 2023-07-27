function Get-ScriptPath {
    if (-not $PSVersionTable.PSVersion -or $PSVersionTable.PSVersion.Major -lt 3) {
        $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    }
    else {
        $scriptPath = $PSScriptRoot
    }
    return $scriptPath
}
$scriptPath = Get-ScriptPath

function Initialize-Logging {
    try {
        $scriptPath = $PSScriptRoot
        $computerName = $env:COMPUTERNAME
        $Filename = "RemoveWSUS"
        $logPath = Join-Path $scriptPath "exports\Logs\$computerName\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
        
        if (!(Test-Path $logPath)) {
            Write-Host "Did not find log file at $logPath" -ForegroundColor Yellow
            Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop | Out-Null
            Write-Host "Created log file at $logPath" -ForegroundColor Yellow
        }
        
        $logFile = Join-Path $logPath "$Filename-Transcript.log"
        Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null

        $CSVFilePath = Join-Path $scriptPath "exports\CSV\$computerName"
        
        if (!(Test-Path $CSVFilePath)) {
            Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
            Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop | Out-Null
            Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Yellow
        }

        return @{
            Filename    = $Filename
            LogPath     = $logPath
            LogFile     = $logFile
            CSVFilePath = $CSVFilePath
        }


        $script:Filename = $Filename
        $script:LogPath = $logPath
        $script:LogFile = $logFile
        $script:CSVFilePath = $CSVFilePath
    }
    catch {
        Write-Error "An error occurred while initializing logging: $_"
    }
}
$loggingInfo = Initialize-Logging

# $DBG


$Filename = $loggingInfo['Filename']
$logPath = $loggingInfo['LogPath']
$logFile = $loggingInfo['LogFile']
$CSVFilePath = $loggingInfo['CSVFilePath']

$DBG


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


function CreateEventLogSource {
    param (
       
        [string]$LogName = 'RemoveWSUSLog'
    )

 


    $source = "RemoveWSUS"
 

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # PowerShell version is less than 6, use New-EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            New-EventLog -LogName $logName -Source $source
            Write-Host "Event source '$source' created in log '$logName'" -ForegroundColor Green
            
        }
        else {
            Write-Host "Event source '$source' already exists" -ForegroundColor Yellow
         
        }
    }
    else {
        # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
        if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
            [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
        
            Write-EnhancedLog -Message "Event source '$source' created in log '$logName'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
        }
        else {
           
            Write-EnhancedLog -Message "Event source '$source' already exists" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }


}
CreateEventLogSource


function Write-EventLogMessage {
    param (
        [string]$Message,
        [string]$LogName = 'RemoveWSUSLog'
    )

    $ErrorActionPreference = 'SilentlyContinue'
    $source = "RemoveWSUS"
    $eventID = 1000
    $hadError = $false

    try {
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            # PowerShell version is less than 6, use Write-EventLog
            Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $eventID -Message $Message
        } else {
            # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
            $eventLog = New-Object System.Diagnostics.EventLog($logName)
            $eventLog.Source = $source
            $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $eventID)
        }

        # Write-host "Event log entry created: $Message" 
    } catch {
        Write-host "Error creating event log entry: $_" 
        $hadError = $true
    }

    if (-not $hadError) {
        # Write-host "Event log message writing completed successfully."
    }
}

function Write-BasicLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO',
        [string]$Caller = (Get-PSCallStack)[0].Command
    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    # Write-Output $formattedMessage
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor

    # Log the message using the PowerShell Logging Module
    # Write-Log -Level $Level -Message $Message

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}


$Message = "Finished Imoprting Modules"
Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)


#################################################################################################################################
################################################# START LOGGING ###################################################################
#################################################################################################################################




function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
        [string]$Level = 'INFO',
        [switch]$UseModule = $false,

        [string]$Caller = (Get-PSCallStack)[0].Command

    )

    # Add timestamp and computer name to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"
    

    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    $Host.UI.RawUI.BackgroundColor = $BackgroundColor
    # Write-Output $formattedMessage
    Write-output $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor

    # Append to CSV file
    AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
    AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath

    # Write to event log (optional)
    Write-EventLogMessage -Message $formattedMessage
}

#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################






$file_extension = ".detectWin32WSUSRemove"


function CreateDetectionFile {
    $ErrorActionPreference = 'SilentlyContinue'
    $filePath = "C:\Intune\Win32\RemoveWSUS\detect$file_extension"
    $hadError = $false

    try {
        if (-not (Test-Path -Path (Split-Path $filePath))) {
            New-Item -ItemType Directory -Path (Split-Path $filePath) -Force
            Write-EnhancedLog -Message "Created detection directory: $(Split-Path $filePath)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }

        New-Item -ItemType File -Path $filePath -Force
        Write-EnhancedLog -Message "Created detection file: $filePath" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
    catch {
        Write-EnhancedLog -Message "Error creating detection file or directory: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        $hadError = $true
    }

    if (-not $hadError) {
        Write-EnhancedLog -Message "Detection file creation completed successfully. file C:\Intune\Win32\RemoveWSUS\detect$file_extension " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
}

CreateDetectionFile







function Remove-WSUSConfig {
    $ErrorActionPreference = 'SilentlyContinue'
    $registryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
    $registryPathAU = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
    $hadError = $false

    $keysToRemove = @('WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnable')
    foreach ($key in $keysToRemove) {
        try {
            if (Get-ItemProperty -Path $registryPath -Name $key -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $registryPath -Name $key -Force
                Write-EnhancedLog "Removed property '$key' from '$registryPath'"
            }
            else {
                Write-EnhancedLog "Property '$key' not found in '$registryPath'"
            }
        }
        catch {
            Write-EnhancedLog "Error removing property '$key' from '$registryPath': $_"
            $hadError = $true
        }
    }

    $propertiesToSet = @{
        'UseWUServer'                = 0;
        'NoAutoUpdate'               = 0;
        'DisableWindowsUpdateAccess' = 0;
    }

    foreach ($property in $propertiesToSet.Keys) {
        try {
            $path = if ($property -eq 'DisableWindowsUpdateAccess') { $registryPath } else { $registryPathAU }
            Set-ItemProperty -Path $path -Name $property -Value $propertiesToSet[$property] -Force
            Write-EnhancedLog "Set property '$property' to $($propertiesToSet[$property]) in '$path'"
        }
        catch {
            Write-EnhancedLog "Error setting property '$property' in '$path': $_"
            $hadError = $true
        }
    }

    try {
        Restart-Service -Name wuauserv
        Write-EnhancedLog "Restarted 'wuauserv' service"
    }
    catch {
        Write-EnhancedLog "Error restarting 'wuauserv' service: $_"
        $hadError = $true
    }

    if (-not $hadError) {
        Write-EnhancedLog -Message "Completed Remove-WSUSConfig " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
}

Remove-WSUSConfig











        
