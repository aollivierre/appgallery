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
    # [String]$DeploymentType = 'UnInstall',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]

    #change the following - AOllivierre
    # [String]$DeployMode = 'Interactive',
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


        # $ErrorActionPreference = "SilentlyContinue"
		# Set ScripRoot variable to the path which the script is executed from
		# $ScriptRoot1 = $null
		# $ScriptRoot1 = if ($PSVersionTable.PSVersion.Major -lt 3) {
		# 	Split-Path -Path $MyInvocation.MyCommand.Path
		# }
		# else {
		# 	$PSScriptRoot
		# }
	
		# Get public and private function definition files.
		# $Public = "$ScriptRoot1\Public"
		# $Private = "$ScriptRoot1\Private"
		# $PSScripts_1 = @( Get-ChildItem -Path $Public\*.ps1 -Recurse -ErrorAction SilentlyContinue )			
		# #Dot source the files
		# Foreach ($import in @($PSScripts_1)) {
		# 	Try {
	
		# 		Write-host "processing $import"
		# 		#         $files = Get-ChildItem -Path $root -Filter *.ps1
		# 		. $import.fullname
		# 	}
		# 	Catch {
		# 		Write-Error -Message "Failed to import function $($import.fullname): $_"
		# 	}
		# }



        #! Lessons learned - run the Load-Modulefile on the "SecretManagement.KeePass" module BEFORE YOU RUN Register-KeepassSecretVault otherwise the config file will contain the vault

		# $Modules = Get-Childitem -path "$ScriptRoot1\public\Modules\*"
		# try { Load-ModuleFile -ModulesPath $Modules } 
		# catch [Exception] {
			
		# 	Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
		# 	Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
		# 	# Write-Host $PSItem -ForegroundColor Red
		# 	$PSItem
		# 	Write-Host $PSItem.ScriptStackTrace -ForegroundColor Red
						
						
		# 	$ErrorMessage_3 = $_.Exception.Message
		# 	write-host $ErrorMessage_3  -ForegroundColor Red
		# 	Write-Output "Ran into an issue: $PSItem"
		# 	Write-host "Ran into an issue: $PSItem" -ForegroundColor Red
		# 	throw "Ran into an issue: $PSItem"
		# 	throw "I am the catch"
		# 	throw "Ran into an issue: $PSItem"
		# 	$PSItem | Write-host -ForegroundColor
		# 	$PSItem | Select-Object *
		# 	$PSCmdlet.ThrowTerminatingError($PSitem)
		# 	throw
		# 	throw "Something went wrong"
		# 	Write-Log $PSItem.ToString()
					
		# }

        # Import-Module -Name "SecretManagement.KeePass" -Force


        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name "NuGet" -Force
        Install-Module -Name "PowerShellGet" -AllowClobber -Force
        Install-Module -Name "SecretManagement.KeePass" -RequiredVersion 0.9.2 -Force:$true
        # Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Force:$true


        ##*===============================================
        ##* INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Installation'

        $options_1 = $null
        $cmdArgs_1 = $null



        #Connect to Azure

        #Retreive License Key from Azure Key Vault

        # $License_Key = $null
        # $License_Key = "ENTER YOUR LICENSE KEY HERE"
        # $License_Key = "ENTER YOUR LICENSE KEY HERE"

        # Register-KeepassSecretVault -Path "C:\Code\KeePass\Database.kdbx" -KeyPath "C:\Code\KeePass\Database.keyx"
        # Register-KeepassSecretVault -Path C:\Code\PSAppDeployToolkit_v3.9.2\Toolkit\Secrets\Database.kdbx" -KeyPath "C:\Code\PSAppDeployToolkit_v3.9.2\Toolkit\Secrets\Database.keyx"

        # C:\Code\PSAppDeployToolkit_v3.9.2\Toolkit\Secrets


        $toolkitPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        $secretsPath = Join-Path $toolkitPath "Secrets"
        $databaseKdbxPath = Join-Path $secretsPath "Database.kdbx"
        $databaseKeyxPath = Join-Path $secretsPath "Database.keyx"


        # $DBG
        
        # Register-KeepassSecretVault -Name "KeePass_DB" -Path $databaseKdbxPath -KeyPath $databaseKeyxPath

        Get-secretvault | Unregister-SecretVault
        Register-KeepassSecretVault -Path $databaseKdbxPath -KeyPath $databaseKeyxPath

        # New-KeePassDatabaseConfiguration -DatabaseProfileName 'KeyFileDB' -DatabasePath "C:\dev\git\PSKeePass\Test\Includes\AuthenticationDatabases\KeyFile.kdbx" -KeyPath "C:\dev\git\PSKeePass\Test\Includes\AuthenticationDatabases\KeyFile.key"


        # New-KeePassDatabaseConfiguration -DatabaseProfileName 'KeyFileDB' -DatabasePath $databaseKdbxPath -KeyPath $databaseKeyxPath

        $LicenseKey = $null
        $LicenseKey = Get-Secret -Name "KnowBe4_LicenseKey" -Vault "Database" -AsPlainText
        # $LicenseKey = Get-KeePassEntry -KeePassEntryGroupPath 'pskeepasstestdatabase/General' -AsPlainText -DatabaseProfileName "KeyFileDB"
        # $LicenseKey = Get-KeePassEntry -title "KnowBe4_LicenseKey" -AsPlainText -DatabaseProfileName "KeyFileDB"

        # $LicenseKey = Get-Secret -Name "KnowBe4_LicenseKey" -Vault "Database"


        # $DBG

        # $Components_Args = $null
        # $Components_Args = "KnowBe4 Phish Alert Button" + ":" + "$License_Key"
        # $Components_Args = "KnowBe4 Phish Alert Button"
        # $Components_Args = "KnowBe4 Phish Alert Button":"LICENSEKEY=$License_Key"
                
        

        # & "c:\code\KnowBe4\PhishAlertButtonSetup.exe" /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=ENTER YOUR LICENSE KEY HERE"
		
        # $options_1 = @(

        #     "/q"
        #     '/ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=ENTER YOUR LICENSE KEY HERE"'
    
        # )


        # $licenseKey = "My License Key"
        $options_1 = @(
            "/q",
            "/ComponentArgs `"KnowBe4 Phish Alert Button`":`"LICENSEKEY=$licenseKey`""
        )
    

        $cmdArgs_1 = @(
            $options_1
        )



        #turned off the Zero-config MS Installations code below to prevent PSADT from installing from the MSI file in the files folder.
        #KnowBe4 as per this article https://support.knowbe4.com/hc/en-us/articles/7142051893011#PREREQ recommends the EXE version instead of the MSI version
        #I'm only including the MSI file which I found by using Search Everything x64 under C:\Users\administrator\AppData\Local\Temp\{A6481A14-196A-4EC2-A025-903C21EBFB58}\PhishAlertButtonSetup.msi
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


        # & "c:\code\KnowBe4\PhishAlertButtonSetup.exe" $cmdArgs_1
        # Execute-Process "c:\code\KnowBe4\PhishAlertButtonSetup.exe" $cmdArgs_1

        # Execute-Process -Path 'PhishAlertButtonSetup.exe' -Parameters "/s /v`"ALLUSERS=1 /qn /L* \`"$configToolkitLogDir\$installName.log`"`""
        # Execute-Process -Path 'PhishAlertButtonSetup.exe' -Parameters "/q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=ENTER YOUR LICENSE KEY HERE""""
        Execute-Process -Path 'PhishAlertButtonSetup.exe' -Parameters "$cmdArgs_1"
        

        # & "c:\code\KnowBe4\PhishAlertButtonSetup.exe" /q /ComponentArgs "KnowBe4 Phish Alert Button":"LICENSEKEY=ENTER YOUR LICENSE KEY HERE""

        ##*===============================================
        ##* POST-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Post-Installation'

        ## <Perform Post-Installation tasks here>


        Get-secretvault | Unregister-SecretVault

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


        # $Uninstall_cmdArgs_1 = $null
        # $UnInstall_options_1 = $null
        


        # $UnInstall_options_1 = @(

        # "/X{F4410196-6904-4B3D-B8BC-D92EB60C9431}", "/qn", "/L*v", "$env:TEMP\poeuninstalllog.txt"
        # "/X{F4410196-6904-4B3D-B8BC-D92EB60C9431}"
      
        # )

        # $Uninstall_cmdArgs_1 = @(
        # $UnInstall_options_1
        # )

        ## Handle Zero-Config MSI Uninstallations
        If ($useDefaultMsi) {
            [Hashtable]$ExecuteDefaultMSISplat = @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) {
                $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile)
            }
            Execute-MSI @ExecuteDefaultMSISplat
        }

        ## <Perform Uninstallation tasks here>

        #This is the official uninstallation command from KnowBe4 https://support.knowbe4.com/hc/en-us/articles/7142051893011#UNINSTALL but I let the Zero-Config above handle the uninstallation using the PSADT built-in Execute-MSI. I'm only providing the MSI file in the files folder for the Uninstaller to work
        # MsiExec.exe /X{F4410196-6904-4B3D-B8BC-D92EB60C9431} /qn /L*v "%TEMP%\poeuninstalllog.txt"    

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
