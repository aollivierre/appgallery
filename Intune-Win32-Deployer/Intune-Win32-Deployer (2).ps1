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


# Load configuration
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

$AOscriptDirectory = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    
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



# Assuming secrets.json is in the same directory as your script
$secretsPath = Join-Path -Path $PSScriptRoot -ChildPath "secrets.json"

# Load the secrets from the JSON file
$secrets = Get-Content -Path $secretsPath -Raw | ConvertFrom-Json

# Now populate the connection parameters with values from the secrets file
$connectionParams = @{
    clientId     = $secrets.clientId
    tenantID     = $secrets.tenantID
    ClientSecret = $secrets.ClientSecret
}


# $TenantName = "bcclsp.org"

# $global:programfoldername = 'PR4B-BackupOutlookSignaturesLite2'


####################################################################################
#   GUID
####################################################################################



function Add-GuidToPs1Files {
    param (
        [string]$AOscriptDirectory,
        [string]$programfoldername
    )

    # Validate the root script directory
    if (-Not (Test-Path -Path $AOscriptDirectory)) {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): The specified script root directory does not exist: $AOscriptDirectory" -ForegroundColor Red
        return
    }

    # Define the target folder within the provided directory
    $targetFolder = Join-Path -Path $AOscriptDirectory -ChildPath "apps-winget\$programfoldername"

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
        }
        catch {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Failed to modify file: $($file.FullName). Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): Completed modifications. Global Tracking ID: $global:AOguidString" -ForegroundColor Cyan
}

# Example usage:
# Add-GuidToPs1Files -AOscriptDirectory $AOscriptDirectory




####################################################################################
#   GUID - End
####################################################################################


function Get-CustomWin32AppName {
    [CmdletBinding()]
    param(
        [string]$PRGID  # Adding a parameter for PRG.ID
    )

    process {
        if (-not [string]::IsNullOrWhiteSpace($PRGID)) {
            # If PRG.ID is provided and valid, use it
            $global:CustomWin32AppName = $PRGID
        }
        else {
            # Otherwise, prompt the user for input
            $userInput = Read-Host "Enter Custom Win32 App Name or press Enter to use the global GUID"

            if ([string]::IsNullOrWhiteSpace($userInput)) {
                if ([string]::IsNullOrWhiteSpace($global:AOguidString)) {
                    Write-Warning "Global GUID is not set. Please enter a Custom Win32 App Name."
                    Get-CustomWin32AppName -PRGID $PRGID  # Recursively call the function with the PRGID parameter
                }
                else {
                    $global:CustomWin32AppName = $global:AOguidString
                }
            }
            else {
                $global:CustomWin32AppName = $userInput
            }
        }

        Write-Output "Using Custom Win32 App Name: $global:CustomWin32AppName"
    }
}

# Get-CustomWin32AppName

function Compile-Win32_intunewin {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Prg,

        [Parameter(Mandatory)]
        [string]$Repo_winget,

        [Parameter(Mandatory)]
        [string]$IntuneWinAppUtil_online
    )

    Write-EnhancedLog -Message "Entering Compile-Win32_intunewin" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)

    $Prg_Path = Join-Path -Path $Repo_winget -ChildPath $Prg.id
    New-Item $Prg_Path -Type Directory -Force

    # Set application name if not present
    if (-not $Prg.name) {
        $Prg.name = $global:CustomWin32AppName
    }


    # Check for application image
    $Prg_img = if (Test-Path -Path (Join-Path -Path $Prg_Path -ChildPath "$($Prg.id).png")) {
        Join-Path -Path $Prg_Path -ChildPath "$($Prg.id).png"
    }
    else {
        "$Repo_Path\ressources\template\winget\winget-managed.png"
    }

    # Download the latest IntuneWinAppUtil
    Invoke-WebRequest -Uri $IntuneWinAppUtil_online -OutFile "$Repo_Path\ressources\IntuneWinAppUtil.exe" -UseBasicParsing

    # Create the .intunewin file
    Start-Process -FilePath "$Repo_Path\ressources\IntuneWinAppUtil.exe" -ArgumentList "-c `"$Prg_Path`" -s install.ps1 -o `"$Prg_Path`" -q" -Wait -WindowStyle Hidden

    Upload-Win32App -Prg $Prg -Prg_Path $Prg_Path -Prg_img $Prg_img

    Write-EnhancedLog -Message "Exiting Compile-Win32_intunewin" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}

function Upload-Win32App {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Prg,

        [Parameter(Mandatory)]
        [string]$Prg_Path,

        [string]$Prg_img
    )

    Write-EnhancedLog -Message "entering Upload-Win32App " -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    Write-EnhancedLog -Message "Uploading: $($Prg.name)" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)

    

    # Define app upload logic here
    # Ensure you have the logic to upload the app using the $Session obtained from Connect-MSIntuneGraph

    try {
       
        # # Graph Connect 

        # Define the parameters for non-interactive connection
    
        # Call the Connect-MSIntuneGraph function with splatted parameters
        Write-EnhancedLog -Message "calling Connect-MSIntuneGraph with connectionParams " -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)


        $Session = Connect-MSIntuneGraph @connectionParams



        Write-EnhancedLog -Message "connecting to Graph using Connect-MSIntuneGraph - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


        $IntuneWinFile = "$Prg_Path\install.intunewin"

        Write-EnhancedLog -Message "set IntuneWinFile path - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
      

        ##################################################################################################################################
        ##################################################################################################################################
        #####################################################################Modify the following parameters##############################
        ##################################################################################################################################


        # read Displayname 
        $DisplayName = "$($Prg.Name)"


        Write-EnhancedLog -Message "set Displayname - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


        # create detection rule

        Write-EnhancedLog -Message "calling New-IntuneWin32AppDetectionRuleScript in progress " -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)


        $detectionScriptPath = Join-Path -Path $Prg_Path -ChildPath "check.ps1"

        if (-not (Test-Path -Path $detectionScriptPath)) {
            Write-Warning "Detection rule script file does not exist at path: $detectionScriptPath"
            # Handle the missing file, e.g., skip this app, use a default detection rule, etc.
        }
        else {
            # Proceed with creating the detection rule and the rest of the script
            $detectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $detectionScriptPath -EnforceSignatureCheck $false -RunAs32Bit $false
            # Make sure to include this detection rule in your app upload parameters
        }
    


        Write-EnhancedLog -Message "set detection rule (calling New-IntuneWin32AppDetectionRuleScript) - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
       



        Write-EnhancedLog -Message "starting to set min requirements - in-progress" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        # minimum requirements
        $RequirementRule = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedWindowsRelease 1607


        Write-EnhancedLog -Message "set min requirements - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

        # picture for win32 app (shown in company portal)
        $Icon = New-IntuneWin32AppIcon -FilePath $Prg_img


        Write-EnhancedLog -Message "set app icon - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

        # Install/uninstall commands
        # $InstallCommandLine = "Deploy-Application.exe"
        # $InstallCommandLine = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1"
        # $InstallCommandLine = "ServiceUI.exe -process:explorer.exe Deploy-Application.exe"
        # $UninstallCommandLine = "ServiceUI.exe -process:explorer.exe Deploy-Application.exe -DeploymentType Uninstall"
        # $UninstallCommandLine = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\uninstall.ps1"
        # $UninstallCommandLine = "Deploy-Application.exe -DeploymentType Uninstall"
       



        # Updated hashtable with new parameters and placeholder values

        # Conditional command lines based on $config.serviceUIPSADT
        if ($config.serviceUIPSADT -eq $true) {
            $InstallCommandLine = "ServiceUI.exe -process:explorer.exe Deploy-Application.exe"
            $UninstallCommandLine = "ServiceUI.exe -process:explorer.exe Deploy-Application.exe -DeploymentType Uninstall"
        }
        else {
            $InstallCommandLine = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1"
            $UninstallCommandLine = "%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\uninstall.ps1"
        }


        
        Write-EnhancedLog -Message "set install/uninstall commands - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

    
       
        Write-EnhancedLog -Message "setting IntuneAppParams - inprogress" -Level "WARNING" -ForegroundColor ([ConsoleColor]::YELLOW)

        # Define $IntuneAppParams with the conditional command lines

        # Assuming $config has already been loaded with the JSON content

  # Assuming $DisplayName and $config.InstallExperience are already defined
$DisplayNameWithInstallExperience = "$DisplayName ($($config.InstallExperience))"

$IntuneAppParams = @{
    FilePath                 = $IntuneWinFile # Dynamic PowerShell variable
    DisplayName              = $DisplayNameWithInstallExperience # Updated to include InstallExperience
    Description              = $DisplayNameWithInstallExperience # Assuming you want the Description to be the same as DisplayName
    Publisher                = $config.Publisher # Static value from JSON
    AppVersion               = $config.AppVersion # Static value from JSON
    Developer                = $config.Developer # Static value from JSON
    Owner                    = $config.Owner # Static value from JSON
    Notes                    = $global:lineToAdd # Dynamic PowerShell global variable
    CompanyPortalFeaturedApp = [System.Convert]::ToBoolean($config.CompanyPortalFeaturedApp) # Static value from JSON
    InstallCommandLine       = $InstallCommandLine # Dynamic PowerShell variable
    UninstallCommandLine     = $UninstallCommandLine # Dynamic PowerShell variable
    InstallExperience        = $config.InstallExperience # Static value from JSON
    RestartBehavior          = $config.RestartBehavior # Static value from JSON
    DetectionRule            = $DetectionRule # Dynamic PowerShell variable
    RequirementRule          = $RequirementRule # Dynamic PowerShell variable
    Icon                     = $Icon # Dynamic PowerShell variable
    InformationURL           = $config.InformationURL # Static value from JSON
    PrivacyURL               = $config.PrivacyURL # Static value from JSON
}


        

        # Use splatting to pass the hashtable as parameters to the cmdlet
        # Upload 


        Write-EnhancedLog -Message "setting IntuneAppParams - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

        #    Write-EnhancedLog -Message "outputting the content of IntuneAppParams - inprogress" -Level "WARNING" -ForegroundColor ([ConsoleColor]::YELLOW)
        #    $IntuneAppParams 


        Write-EnhancedLog -Message "calling Add-IntuneWin32App with IntuneAppParams - inprogress" -Level "WARNING" -ForegroundColor ([ConsoleColor]::YELLOW)

        $upload = Add-IntuneWin32App @IntuneAppParams

       
        Write-EnhancedLog -Message "calling Add-IntuneWin32App - done" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

        Write-EnhancedLog -Message "Upload completed: $($Prg.name)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


    }
  

       
    
    catch {
        Write-Host "Error uploading application $($Prg.Name)" -ForegroundColor Red
        Write-Host $_
    }

    Start-Sleep -Seconds 10

    Write-EnhancedLog -Message "Calling Create-AADGroup for $($Prg.name)" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    Create-AADGroup -Prg $Prg
    Write-EnhancedLog -Message "Completed Create-AADGroup for $($Prg.name)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)

}


function Create-AADGroup ($Prg) {


    # Convert the Client Secret to a SecureString
    $SecureClientSecret = ConvertTo-SecureString $connectionParams.ClientSecret -AsPlainText -Force

    # Create a PSCredential object with the Client ID as the user and the Client Secret as the password
    $ClientSecretCredential = New-Object System.Management.Automation.PSCredential ($connectionParams.ClientId, $SecureClientSecret)

    # Connect to Microsoft Graph
    Connect-MgGraph -TenantId $connectionParams.TenantId -ClientSecretCredential $ClientSecretCredential

    # Your code that interacts with Microsoft Graph goes here


    # Create Group
    # $grpname = "$($global:SettingsVAR.AADgrpPrefix )$($Prg.id)"
    Write-EnhancedLog -Message "setting Group Name" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    $grpname = "SG007 - Intune - Apps - Microsoft Teams - WinGet - Windows Package Manager"
    if (!$(Get-MgGroup -Filter "DisplayName eq '$grpname'")) {
        # Write-Host "  Create AAD group for assigment:  $grpname" -Foregroundcolor cyan

        Write-EnhancedLog -Message " Did not find Group $grpname " -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
        
        # $GrpObj = New-MgGroup -DisplayName "$grpname" -Description "App assigment: $($Prg.id) $($Prg.manager)" -MailEnabled:$False  -MailNickName $grpname -SecurityEnabled
    }
    else { $GrpObj = Get-MgGroup -Filter "DisplayName eq '$grpname'" }


    Write-EnhancedLog -Message " Assign Group > $grpname <  to  > $($Prg.Name)" -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
  


    Write-EnhancedLog -Message " calling Get-IntuneWin32App " -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    $Win32App = Get-IntuneWin32App -DisplayName "$($Prg.Name)"


    Write-EnhancedLog -Message " calling Get-IntuneWin32App - done " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)


    Write-EnhancedLog -Message " calling Add-IntuneWin32AppAssignmentGroup " -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
    Add-IntuneWin32AppAssignmentGroup -Include -ID $Win32App.id -GroupID $GrpObj.id -Intent "available" -Notification "showAll"


    Write-EnhancedLog -Message " calling Add-IntuneWin32AppAssignmentGroup - done " -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
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

# Create-WingetWin32App
# Define the properties of the Win32 app
$Prg = [PSCustomObject]@{
    # id          = "BackupOutlookSignaturesLite1"
    # id          = "PR4B-BackupOutlookSignaturesLite3"
    # id          = "FortiClientEMSv7_Bellwoods-v4"
    # id          = "PR4B-SetAdobeReaderPDFDefault-v10"
    id          = $config.ID
    name        = "$global:CustomWin32AppName"
    Description = "$global:CustomWin32AppName"
}

# $global:programfoldername = 'PR4B-BackupOutlookSignaturesLite2'
# $global:programfoldername = 'BackupOutlookSignatures2'


Add-GuidToPs1Files -AOscriptDirectory $AOscriptDirectory -programfoldername $Prg.id

# Now, call the Get-CustomWin32AppName function and pass $Prg.ID to it
Get-CustomWin32AppName -PRGID $Prg.ID

# Call the Compile-Win32_intunewin function with the specified parameters
Compile-Win32_intunewin -Prg $Prg -Repo_winget $Repo_winget -IntuneWinAppUtil_online $IntuneWinAppUtil_online

stop-transcript