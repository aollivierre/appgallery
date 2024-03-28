<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'silent',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## Variables: Application
    [String]$appVendor = ''
    [String]$appName = ''
    [String]$appVersion = ''
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = 'XX/XX/20XX'
    [String]$appScriptAuthor = '<author name>'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.9.2'
    [String]$deployAppScriptDate = '02/02/2023'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Installation tasks here>


        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        ## Handle Zero-Config MSI Installations
        # If ($useDefaultMsi) {
        #     [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) {
        #         $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
        #     }
        #     Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) {
        #         $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ }
        #     }
        # }

        ## <Perform Installation tasks here>



        
#         function Get-ScriptPath {
#             if (-not $PSVersionTable.PSVersion -or $PSVersionTable.PSVersion.Major -lt 3) {
#                 $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#             }
#             else {
#                 $scriptPath = $PSScriptRoot
#             }
#             return $scriptPath
#         }
#         $scriptPath = Get-ScriptPath
        
#         function Initialize-Logging {
#             try {
#                 $scriptPath = $PSScriptRoot
#                 $computerName = $env:COMPUTERNAME
#                 $Filename = "RemoveWSUS"
#                 $logPath = Join-Path $scriptPath "exports\Logs\$computerName\$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss')"
                
#                 if (!(Test-Path $logPath)) {
#                     Write-Host "Did not fin log file at $logPath" -ForegroundColor Yellow
#                     Write-Host "Creating log file at $logPath" -ForegroundColor Yellow
#                     New-Item -ItemType Directory -Path $logPath -Force -ErrorAction Stop | Out-Null
#                     Write-Host "Created log file at $logPath" -ForegroundColor Yellow
#                 }
                
#                 $logFile = Join-Path $logPath "$Filename-Transcript.log"
#                 Start-Transcript -Path $logFile -ErrorAction Stop | Out-Null
        
#                 $CSVFilePath = Join-Path $scriptPath "exports\CSV\$computerName"
                
#                 if (!(Test-Path $CSVFilePath)) {
#                     Write-Host "Did not find CSV file at $CSVFilePath" -ForegroundColor Yellow
#                     Write-Host "Creating CSV file at $CSVFilePath" -ForegroundColor Yellow
#                     New-Item -ItemType Directory -Path $CSVFilePath -Force -ErrorAction Stop | Out-Null
#                     Write-Host "Created CSV file at $CSVFilePath" -ForegroundColor Yellow
#                 }
        
#                 return @{
#                     Filename    = $Filename
#                     LogPath     = $logPath
#                     LogFile     = $logFile
#                     CSVFilePath = $CSVFilePath
#                 }
        
        
#                 $script:Filename = $Filename
#                 $script:LogPath = $logPath
#                 $script:LogFile = $logFile
#                 $script:CSVFilePath = $CSVFilePath
#             }
#             catch {
#                 Write-Error "An error occurred while initializing logging: $_"
#             }
#         }
#         $loggingInfo = Initialize-Logging
        
#         # $DBG
        
        
#         $Filename = $loggingInfo['Filename']
#         $logPath = $loggingInfo['LogPath']
#         $logFile = $loggingInfo['LogFile']
#         $CSVFilePath = $loggingInfo['CSVFilePath']
        
#         $DBG
        
        
#         function AppendCSVLog {
#             param (
#                 [string]$Message,
#                 [string]$CSVFilePath
               
#             )
        
#             $csvData = [PSCustomObject]@{
#                 TimeStamp    = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
#                 ComputerName = $env:COMPUTERNAME
#                 Message      = $Message
#             }
        
#             # $csvData | Export-Csv -Path $CSVFilePath -Append -NoTypeInformation -Force
#         }
        
        
#         function CreateEventLogSource {
#             param (
               
#                 [string]$LogName = 'RemoveWSUSLog'
#             )
        
         
        
        
#             $source = "RemoveWSUS"
         
        
#             if ($PSVersionTable.PSVersion.Major -lt 6) {
#                 # PowerShell version is less than 6, use New-EventLog
#                 if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
#                     New-EventLog -LogName $logName -Source $source
#                     Write-Host "Event source '$source' created in log '$logName'" -ForegroundColor Green
                    
#                 }
#                 else {
#                     Write-Host "Event source '$source' already exists" -ForegroundColor Yellow
                 
#                 }
#             }
#             else {
#                 # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
#                 if (-not ([System.Diagnostics.EventLog]::SourceExists($source))) {
#                     [System.Diagnostics.EventLog]::CreateEventSource($source, $logName)
                
#                     Write-EnhancedLog -Message "Event source '$source' created in log '$logName'" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                 }
#                 else {
                   
#                     Write-EnhancedLog -Message "Event source '$source' already exists" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#                 }
#             }
        
        
#         }
#         CreateEventLogSource
        
#         function Write-EventLogMessage {
#             param (
#                 [string]$Message,
#                 [string]$LogName = 'RemoveWSUSLog'
#             )
        
          
        
#             $source = "RemoveWSUS"
#             $eventID = 1000
        
        
#             if ($PSVersionTable.PSVersion.Major -lt 6) {
#                 # PowerShell version is less than 6, use Write-EventLog
#                 Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId $eventID -Message $Message
              
#             }
#             else {
#                 # PowerShell version is 6 or greater, use System.Diagnostics.EventLog
#                 $eventLog = New-Object System.Diagnostics.EventLog($logName)
#                 $eventLog.Source = $source
#                 $eventLog.WriteEntry($Message, [System.Diagnostics.EventLogEntryType]::Information, $eventID)
             
#             }
        
        
#         }
        
#         function Write-BasicLog {
#             param (
#                 [string]$Message,
#                 [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
#                 [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
#                 [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
#                 [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
#                 [string]$Level = 'INFO',
#                 [string]$Caller = (Get-PSCallStack)[0].Command
#             )
        
#             # Add timestamp and computer name to the message
#             $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"
        
#             # Write the message with the specified colors
#             $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
#             $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
#             $Host.UI.RawUI.ForegroundColor = $ForegroundColor
#             $Host.UI.RawUI.BackgroundColor = $BackgroundColor
#             # Write-Output $formattedMessage
#             Write-output $formattedMessage
#             $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
#             $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor
        
#             # Log the message using the PowerShell Logging Module
#             # Write-Log -Level $Level -Message $Message
        
#             # Append to CSV file
#             AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
#             AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath
        
#             # Write to event log (optional)
#             Write-EventLogMessage -Message $formattedMessage
#         }
        
        
#         function Install-LoggingModules {
#             # Set up security protocol
#             # [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls13
#             [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        
#             # Check if NuGet package provider is installed
#             $NuGetProvider = Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue
        
#             # Install NuGet package provider if not installed
#             if (-not $NuGetProvider) {
#                 $Message = "NuGet package provider not found. Installing..."
#                 Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Yellow)
#                 Install-PackageProvider -Name "NuGet" -Force
#             }
#             else {
#                 $Message = "NuGet package provider is already installed."
#                 Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)
#             }
        
#             # Install PowerShellGet module if not installed
#             $PowerShellGetModule = Get-Module -Name "PowerShellGet" -ListAvailable
#             if (-not $PowerShellGetModule) {
#                 $Message = "Installing PowerShellGet"
#                 Write-BasicLog -Message $Message
#                 Install-Module -Name "PowerShellGet" -AllowClobber -Force
                
#             }
#             else {
#                 $Message = "PowerShellGet is already installed."
#                 Write-BasicLog -Message $Message
#             }
            
        
#             # $requiredModules = @("Logging")
        
#             # foreach ($module in $requiredModules) {
#             #     if (!(Get-Module -ListAvailable -Name $module)) {
#             #         $Message = "Installing module: $module"
#             #         Write-BasicLog -Message $Message
#             #         Install-Module -Name $module -Force
#             #         $Message = "Module: $module has been installed"
#             #         Write-BasicLog -Message $Message
        
#             #     }
#             #     else {
#             #         $Message = "Module $module is already installed"
#             #         Write-BasicLog -Message $Message
#             #     }
#             # }
        
        
#             # $ImportedModules = @("Logging")
            
#             # foreach ($Importedmodule in $ImportedModules) {
#             #     if ((Get-Module -ListAvailable -Name $Importedmodule)) {
        
#             #         $Message = "Importing module: $Importedmodule"
#             #         Write-BasicLog -Message $Message
#             #         Import-Module -Name $Importedmodule
#             #         $Message = "Module: $Importedmodule has been Imported"
#             #         Write-BasicLog -Message $Message
#             #     }
#             # }
        
#         }
#         # Call the function to install the required modules and dependencies
#         # Install-LoggingModules
        
#         $Message = "Finished Imorting Modules"
#         Write-BasicLog -Message $Message -ForegroundColor ([ConsoleColor]::Green)
        
        
#         #################################################################################################################################
#         ################################################# START LOGGING ###################################################################
#         #################################################################################################################################
        
        
#         # function Initialize-EnhancedLogging {
#         #     param (
#         #         [string]$logFile
#         #     )
        
#         #     Set-LoggingDefaultLevel -Level 'WARNING'
#         #     Add-LoggingTarget -Name Console
#         #     Add-LoggingTarget -Name File -Configuration @{Path = $logFile }
#         # }
        
#         # Initialize-EnhancedLogging -logFile $logFilePath
        
        
#         function Write-EnhancedLog {
#             param (
#                 [string]$Message,
#                 [string]$CSVFilePath = "$scriptPath\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
#                 [string]$CentralCSVFilePath = "$scriptPath\exports\CSV\$Filename.csv",
#                 [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
#                 [ConsoleColor]$BackgroundColor = [ConsoleColor]::Black,
#                 [string]$Level = 'INFO',
#                 [switch]$UseModule = $false,
#                 # [string]$Caller = (Get-PSCallStack)[1].FunctionName
#                 # [string]$Caller = (Get-PSCallStack)[1].InvocationInfo.MyCommand.Name
#                 [string]$Caller = (Get-PSCallStack)[0].Command
        
#             )
        
#             # Add timestamp and computer name to the message
#             $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Caller] $Message"
        
        
#             # $formattedMessage = "[$Caller] $Message"
        
            
        
#             # Write the message with the specified colors
#             $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
#             $currentBackgroundColor = $Host.UI.RawUI.BackgroundColor
#             $Host.UI.RawUI.ForegroundColor = $ForegroundColor
#             $Host.UI.RawUI.BackgroundColor = $BackgroundColor
#             # Write-Output $formattedMessage
#             Write-output $formattedMessage
#             $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
#             $Host.UI.RawUI.BackgroundColor = $currentBackgroundColor
        
#             # Log the message using the PowerShell Logging Module
#             # $UseModule = $true
#             # if ($UseModule) {
#             #     Write-Log -Level $Level -Message $formattedMessage
#             # } else {
#             #     Write-Output $formattedMessage -ForegroundColor $ForegroundColor
#             # }
        
#             # Append to CSV file
#             AppendCSVLog -Message $Message -CSVFilePath $CSVFilePath
#             AppendCSVLog -Message $Message -CSVFilePath $CentralCSVFilePath
        
#             # Write to event log (optional)
#             Write-EventLogMessage -Message $formattedMessage
#         }
        
#         #################################################################################################################################
#         ################################################# END LOGGING ###################################################################
#         #################################################################################################################################
        
#         function Install-RequiredModules {
        
#             [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
#             # Install SecretManagement.KeePass module if not installed or if the version is less than 0.9.2
#             $KeePassModule = Get-Module -Name "SecretManagement.KeePass" -ListAvailable
#             if (-not $KeePassModule -or ($KeePassModule.Version -lt [System.Version]::new(0, 9, 2))) {
        
#                 Write-EnhancedLog -Message "Installing SecretManagement.KeePass " -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                 Install-Module -Name "SecretManagement.KeePass" -RequiredVersion 0.9.2 -Force:$true
#             }
#             else {
#                 # Write-Host "SecretManagement.KeePass is already installed." -ForegroundColor Green
#                 Write-EnhancedLog -Message "SecretManagement.KeePass is already installed." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#             }
        
        
#             $requiredModules = @("Microsoft.Graph", "Microsoft.Graph.Authentication")
        
#             foreach ($module in $requiredModules) {
#                 if (!(Get-Module -ListAvailable -Name $module)) {
        
#                     Write-EnhancedLog -Message "Installing module: $module" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                     Install-Module -Name $module -Force
#                     Write-EnhancedLog -Message "Module: $module has been installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                 }
#                 else {
#                     Write-EnhancedLog -Message "Module $module is already installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                 }
#             }
        
        
#             $ImportedModules = @("Microsoft.Graph.Identity.DirectoryManagement", "Microsoft.Graph.Authentication")
            
#             foreach ($Importedmodule in $ImportedModules) {
#                 if ((Get-Module -ListAvailable -Name $Importedmodule)) {
#                     Write-EnhancedLog -Message "Importing module: $Importedmodule" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                     Import-Module -Name $Importedmodule
#                     Write-EnhancedLog -Message "Module: $Importedmodule has been Imported" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                 }
#             }
        
        
#         }
#         # Call the function to install the required modules and dependencies
#         # Install-RequiredModules
#         Write-EnhancedLog -Message "All modules installed" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)




#         $VaultName = "Database"
#         function Register-KeePassVault {
#             # To securely store the KeePass database credentials, you'll need to register a KeePass vault:
#             $VaultName = $VaultName
        
#             $ExistingVault = Get-SecretVault -Name $VaultName -ErrorAction SilentlyContinue
#             if ($ExistingVault) {
#                 Write-EnhancedLog -Message "Keepass $VaultName is already Registered..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#                 Unregister-SecretVault -Name $VaultName
#                 Register-KeePassSecretVault -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath
#             } 
#             else {
#                 Write-EnhancedLog -Message "Keepass $VaultName is NOT Registered... Registering" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#                 Unregister-SecretVault -Name $VaultName
#                 Register-KeePassSecretVault -Name $VaultName -Path $databaseKdbxPath -KeyPath $databaseKeyxPath
#             }
            
#         }
        
#         Write-EnhancedLog -Message "Successfully Registered KeePass Vault" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        
        
        
#         function Get-KeePassDatabasePaths {
        
#             $secretsPath = Join-Path $scriptPath "Secrets"
#             $databaseKdbxPath = Join-Path $secretsPath "Database.kdbx"
#             $databaseKeyxPath = Join-Path $secretsPath "Database.keyx"
        
#             return @{
        
#                 DatabaseKdbxPath = $databaseKdbxPath
#                 DatabaseKeyxPath = $databaseKeyxPath
#             }
#         }
#         $paths = Get-KeePassDatabasePaths
#         $databaseKdbxPath = $paths['DatabaseKdbxPath']
#         $databaseKeyxPath = $paths['DatabaseKeyxPath']
        
        
#         # $DBG
        
#         Write-EnhancedLog -Message "Successfully built Database Paths" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         # $DBG
        
        
#         Register-KeePassVault
#         Write-EnhancedLog -Message "Finished Registering KeePass" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        
#         function Get-SecretsFromKeePass {
#             param (
#                 [string[]]$KeePassEntryNames
#             )
            
#             $Secrets = @{}
            
#             foreach ($entryName in $KeePassEntryNames) {
#                 $PasswordSecret = Get-Secret -Name "${EntryName}_Password" -Vault "Database"
        
#                 # $DBG
#                 $SecurePassword = $PasswordSecret
                        
#                 # Convert plain text password to SecureString
#                 $SecurePasswordString = ConvertTo-SecureString -String $SecurePassword -AsPlainText -Force
        
#                 # $DBG
                
#                 # Convert SecureString back to plain text
#                 $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordSecret)
#                 $PlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
#                 # $DBG
                
#                 $Secrets[$entryName] = @{
#                     "Username"       = $PasswordSecret.UserName
#                     "SecurePassword" = $SecurePasswordString
#                     "PlainText"      = $PlainText
#                 }
#             }
            
#             return $Secrets
#         }
        
#         $KeePassEntryNames = @("ClientId", "ClientSecret", "TenantName", "SiteObjectId", "WebhookUrl")
#         $Secrets = Get-SecretsFromKeePass -KeePassEntryNames $KeePassEntryNames
        
#         $clientId = $Secrets["ClientId"].PlainText
#         $clientSecret = $Secrets["ClientSecret"].PlainText
#         $tenantName = $Secrets["TenantName"].PlainText
#         $site_objectid = $Secrets["SiteObjectId"].PlainText
#         $webhook_url = $Secrets["WebhookUrl"].PlainText
#         # $tenantname = "pharmacists.ca"
#         Write-EnhancedLog -Message "KeePass secrets are now available" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)






# function Remove-WSUSConfig {
#     $ErrorActionPreference = 'SilentlyContinue'
#     $registryPath = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate'
#     $registryPathAU = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
#     # $logFile = 'Remove-WSUSConfig.log'

#     # function LogWrite($message) {
#     #     $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#     #     "$timestamp $message" | Out-File -FilePath $logFile -Append
#     # }

#     $keysToRemove = @('WUServer', 'TargetGroup', 'WUStatusServer', 'TargetGroupEnable')
#     foreach ($key in $keysToRemove) {
#         if (Get-ItemProperty -Path $registryPath -Name $key -ErrorAction SilentlyContinue) {
#             Remove-ItemProperty -Path $registryPath -Name $key -Force
#             Write-EnhancedLog "Removed property '$key' from '$registryPath'"
#         } else {
#             Write-EnhancedLog "Property '$key' not found in '$registryPath'"
#         }
#     }

#     $propertiesToSet = @{
#         'UseWUServer'                 = 0;
#         'NoAutoUpdate'                = 0;
#         'DisableWindowsUpdateAccess'  = 0;
#     }

#     foreach ($property in $propertiesToSet.Keys) {
#         $path = if ($property -eq 'DisableWindowsUpdateAccess') { $registryPath } else { $registryPathAU }
#         Set-ItemProperty -Path $path -Name $property -Value $propertiesToSet[$property] -Force
#         Write-EnhancedLog "Set property '$property' to $($propertiesToSet[$property]) in '$path'"
#     }

#     Restart-Service -Name wuauserv
#     Write-EnhancedLog "Restarted 'wuauserv' service"
# }

# Remove-WSUSConfig







# $document_drive_name = "Documents"

# # Set the file extension to scan for
# $file_extension = ".detectWin32WSUSRemove"

# # Define functions
# function Get-MicrosoftGraphAccessToken {
#     $tokenBody = @{
#         Grant_Type    = 'client_credentials'  
#         Scope         = 'https://graph.microsoft.com/.default'  
#         Client_Id     = $clientId  
#         Client_Secret = $clientSecret
#     }  

#     $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

#     return $tokenResponse.access_token
# }

# function Get-SharePointDocumentDriveId {
#     $url = "https://graph.microsoft.com/v1.0/groups/$site_objectid/sites/root"
#     $subsite_ID = (Invoke-RestMethod -Headers $headers -Uri $URL -Method Get).ID

#     $url = "https://graph.microsoft.com/v1.0/sites/$subsite_ID/drives"
#     $drives = Invoke-RestMethod -Headers $headers -Uri $url -Method Get

#     $document_drive_id = ($drives.value | Where-Object { $_.name -eq $document_drive_name }).id

#     return $document_drive_id
# }
# function New-SharePointFolder {
#     param($document_drive_id, $parent_folder_path, $folder_name)

#     try {
#         # Check if the folder already exists
#         $check_url = "https://graph.microsoft.com/v1.0/drives/" + $document_drive_id + "/root:/" + $parent_folder_path + ":/children"
#         $existing_folders = Invoke-RestMethod -Headers $headers -Uri $check_url -Method GET
#         $existing_folder = $existing_folders.value | Where-Object { $_.name -eq $folder_name -and $_.folder }

#         if ($existing_folder) {
#             Write-EnhancedLog "Folder '$folder_name' already exists in '$parent_folder_path'. Skipping folder creation."
#             return $existing_folder
#         }
#     }
#     catch {
#         Write-EnhancedLog "Folder '$folder_name' not found in '$parent_folder_path'. Proceeding with folder creation."
#     }

#     # If the folder does not exist, create it
#     $url = "https://graph.microsoft.com/v1.0/drives/" + $document_drive_id + "/root:/" + $parent_folder_path + ":/children"

#     $body = @{
#         "@microsoft.graph.conflictBehavior" = "fail"
#         "name"                              = $folder_name
#         "folder"                            = @{}
#     }

#     Write-EnhancedLog "Creating folder '$folder_name' in '$parent_folder_path'..."
#     $created_folder = Invoke-RestMethod -Headers $headers -Uri $url -Body ($body | ConvertTo-Json) -Method POST
#     Write-EnhancedLog "Folder created successfully."
#     return $created_folder
# }

# function Upload-FileToSharePoint {
#     param($document_drive_id, $file_path, $folder_name)

#     $content = Get-Content -Path $file_path
#     $filename = (Get-Item -Path $file_path).Name

#     $puturl = "https://graph.microsoft.com/v1.0/drives/$document_drive_id/root:/$folder_name/$($filename):/content"

#     $upload_headers = @{
#         "Authorization" = "Bearer $($accessToken)"
#         "Content-Type"  = "text/plain"
#     }

#     $uploadResponse = Invoke-RestMethod -Headers $upload_headers -Uri $puturl -Body $content -Method PUT
# }

# function Send-TeamsMessage {
#     param($webhook_url, $message_text)

#     $message = @{
#         "@type"    = "MessageCard"
#         "@context" = "http://schema.org/extensions"
#         "text"     = $message_text
#     }

#     $params = @{
#         'ContentType' = 'application/json'
#         'Method'      = 'POST'
#         'Body'        = ($message | ConvertTo-Json)
#         'Uri'         = $webhook_url
#     }

#     $Teamsresponse = Invoke-RestMethod @params
# }

# function Scan-FolderForExtension {
#     param($folderPath, $fileExtension)

#     Write-EnhancedLog "Scanning folder '$folderPath' for files with extension '$fileExtension'..."

#     $results = @()

#     if (Test-Path $folderPath) {
#         $files = Get-ChildItem -Path $folderPath -Filter "*$fileExtension" -Recurse -File -ErrorAction SilentlyContinue
#         Write-EnhancedLog "Get-ChildItem returned $($files.Count) files."
            
            
#         $files | ForEach-Object {
#             Write-EnhancedLog "Processing file: $($_.FullName)"
#             $results += $_.FullName
#         }
#     }
#     else {
#         Write-EnhancedLog "Folder path '$folderPath' does not exist."
#     }

#     Write-EnhancedLog "Found $($results.Count) files with extension '$fileExtension' in folder '$folderPath'."

#     return $results
# }



# try {
#     # Get an access token for the Microsoft Graph API
#     $accessToken = Get-MicrosoftGraphAccessToken
    
#     # Set up headers for API requests
#     $headers = @{
#         "Authorization" = "Bearer $($accessToken)"
#         "Content-Type"  = "application/json"
#     }

#     # Get the ID of the SharePoint document drive
#     $document_drive_id = Get-SharePointDocumentDriveId


#     # ... (Previous code remains the same)

#     # Get the computer name and detailed info
#     $computerName = $env:COMPUTERNAME
#     $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem | Format-List | Out-String

#     # $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
#     $allScanResults = @()

#     # foreach ($drive in $drives) {
#         $folderPath = "C:\intune\Win32\RemoveWSUS\"
#         # $folderPath = $folderPath -replace "^C:", "$drive"

#         Write-EnhancedLog "Scanning folder '$folderpath' for files with extension '$file_extension'..."
#         $scanResults = Scan-FolderForExtension -folderPath $folderPath -fileExtension $file_extension
#         $allScanResults += $scanResults
#     # }



#     $detectedFolderPath = "DetectedWSUS"
#     $cleanFolderPath = "Clean"

#     if ($allScanResults.Count -gt 0) {
#         $messageText = "⚠ WSUS detected on computer $computerName! ⚠`n"

#     }
#     else {
#         $messageText = "✅ Computer $computerName is clean. ✅`n"

#     }

#     # Generate a report file containing the paths of the files found
#     Write-EnhancedLog "Generating report..."
#     $reportFileName = "WSUSScanReport_${computerName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
#     $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
#     $CSVFilePath = "$scriptPath\exports\CSV\$Filename.csv"

#     # Add computer info and scan results to the report file
#     $computerInfo | Set-Content -Path $reportFilePath
#     $allScanResults | Add-Content -Path $reportFilePath

#     # Send the report file to the specified Teams channel
#     $messageText += Get-Content -Path $reportFilePath -Raw
#     Write-EnhancedLog "Sending report to Teams channel..."
#     Send-TeamsMessage -webhook_url $webhook_url -message_text $messageText
#     Write-EnhancedLog "Report sent successfully."

#     # Upload the specified file to SharePoint
#     # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name



#     if ($allScanResults.Count -gt 0) {

#         # Create the "Infected" folder in SharePoint if it doesn't exist
#         # New-SharePointFolder -document_drive_id $document_drive_id -folder_path $detectedFolderPath
#         New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $detectedFolderPath -folder_name $computerName

#         # Upload the specified file to the "Infected" folder in SharePoint
#         # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name -parent_folder_path $detectedFolderPath

#         $detectedtargetFolderPath = "$detectedFolderPath/$computerName"
#         Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $detectedtargetFolderPath
#         Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $detectedtargetFolderPath


#     }
#     else {
#         Write-EnhancedLog "No files found with extension '$file_extension'."

#         # Create the "Clean" folder in SharePoint if it doesn't exist
#         # New-SharePointFolder -document_drive_id $document_drive_id -folder_path $cleanFolderPath

#         New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $cleanFolderPath -folder_name $computerName

#         # Upload a "clean" report to the "Clean" folder in SharePoint
#         $reportFileName = "CleanReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
#         $reportFilePath = Join-Path -Path $env:TEMP -ChildPath $reportFileName
#         Set-Content -Path $reportFilePath -Value "No files found with extension '$file_extension'."
#         # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $folder_name -parent_folder_path $cleanFolderPath

#         # Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $targetFolderPath

#         $cleandtargetFolderPath = "$cleanFolderPath/$computerName"
#         Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $reportFilePath -folder_name $cleandtargetFolderPath
#         Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $CSVFilePath -folder_name $cleandtargetFolderPath

#     }


# }
# catch {
#     Write-EnhancedLog "An error occurred: $_"
# }


# # Get-secretvault | Unregister-SecretVault

# # Remove variables and clear secrets
# Remove-Variable -Name clientId
# Remove-Variable -Name clientSecret
# Remove-Variable -Name tenantName
# Remove-Variable -Name site_objectid
# Remove-Variable -Name webhook_url

# $Secrets.Clear()
# Remove-Variable -Name Secrets

# # Stop transcript logging
# Stop-Transcript

# # Create a folder in SharePoint named after the computer
# $computerName = $env:COMPUTERNAME
# $parentFolderPath = "Logs"  # Change this to the desired parent folder path in SharePoint
# New-SharePointFolder -document_drive_id $document_drive_id -parent_folder_path $parentFolderPath -folder_name $computerName

# # Upload the transcript log to the new SharePoint folder
# $targetFolderPath = "$parentFolderPath/$computerName"
# $logFilePath = $logFile
# Upload-FileToSharePoint -document_drive_id $document_drive_id -file_path $logFilePath -folder_name $targetFolderPath









        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>

        ## Display a message at the end of the install
        If (-not $useDefaultMsi) {
            Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait
        }
    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Uninstallation tasks here>


        ##*===============================================
        ##* UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Uninstallation'

        ## Handle Zero-Config MSI Uninstallations
        # If ($useDefaultMsi) {
        #     [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) {
        #         $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
        #     }
        #     Execute-MSI @ExecuteDefaultMSISplat
        # }

        ## <Perform Uninstallation tasks here>



        



        ##*===============================================
        ##* POST-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Uninstallation'

        ## <Perform Post-Uninstallation tasks here>


    }
    ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
        Show-InstallationWelcome -CloseApps 'iexplore' -CloseAppsCountdown 60

        ## Show Progress Message (with the default message)
        Show-InstallationProgress

        ## <Perform Pre-Repair tasks here>

        ##*===============================================
        ##* REPAIR
        ##*===============================================
        [String]$installPhase = 'Repair'

        ## Handle Zero-Config MSI Repairs
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }
        ## <Perform Repair tasks here>

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## <Perform Post-Repair tasks here>


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
