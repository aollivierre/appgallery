#Requires -RunAsAdministrator
#Requires -Version 5.1

[CmdletBinding()]
param()

# Script version
$Script:Version = "1.0.0"
$Script:InstallTimeout = [timespan]::FromMinutes(20)

# Initialize logging
$Script:ScriptName = $MyInvocation.MyCommand.Name
$Script:LogPath = Join-Path $env:TEMP "AccuroPrerequisites_Install.log"
$Script:DownloadPath = Join-Path $env:TEMP "AccuroPrerequisites"

function Write-AccuroPrerequisitesLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level = 'Information'
    )

    $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
    $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
    $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), $Script:ScriptName, $Level
    $Line = $Line -f $LineFormat

    # Create a mutex for thread-safe file access
    $mutex = New-Object System.Threading.Mutex($false, "Global\AccuroPrerequisitesLogMutex")
    try {
        $mutex.WaitOne() | Out-Null
        Add-Content -Value $Line -Path $Script:LogPath -Encoding UTF8
    }
    finally {
        $mutex.ReleaseMutex()
    }
    Write-Host $Message
}

function Test-PendingReboot {
    $rebootPending = $false

    # Check Windows Update
    if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { $rebootPending = $true }
    if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { $rebootPending = $true }

    # Check PendingFileRenameOperations
    if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -EA Ignore) { $rebootPending = $true }

    return $rebootPending
}

function Initialize-Installation {
    Write-AccuroPrerequisitesLog "Starting installation of Accuro prerequisites - Script version $Script:Version"
    
    # Create download directory if it doesn't exist
    if (-not (Test-Path $Script:DownloadPath)) {
        New-Item -ItemType Directory -Path $Script:DownloadPath -Force | Out-Null
    }

    # Check for pending reboots
    if (Test-PendingReboot) {
        Write-AccuroPrerequisitesLog "A system reboot is pending. Please reboot before running this script." -Level Warning
        exit 1
    }
}

function Install-CitrixWorkspace {
    # Check if already installed
    if (Test-Path "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe") {
        $regCheck = Get-ItemProperty "HKLM:\Software\Citrix\Install\Receiver" -ErrorAction SilentlyContinue
        if ($regCheck) {
            Write-AccuroPrerequisitesLog "Citrix Workspace is already installed (Version: $($regCheck.Version))" -Level Information
            return $true
        }
    }

    $citrixUrl = "https://www.cloudwerx.com/update/files/citrix/CitrixWorkspace-19.12.5000.exe"
    $citrixInstaller = Join-Path $Script:DownloadPath "CitrixWorkspace.exe"

    try {
        Write-AccuroPrerequisitesLog "Starting Citrix Workspace download..."
        $downloadSuccess = Start-FileDownloadWithRetry -Source $citrixUrl -Destination $citrixInstaller
        
        if (-not $downloadSuccess) {
            Write-AccuroPrerequisitesLog "Failed to download Citrix Workspace installer" -Level Error
            return $false
        }

        Write-AccuroPrerequisitesLog "Installing Citrix Workspace..."
        
        # Recommended installation arguments based on Citrix documentation
        $arguments = @(
            "/silent"
            "/noreboot"
            "/forceinstall"
            "/install_components=SSON,ICA_Client,USB"
            "/includeSSON"
            "/AutoUpdateCheck=disabled"
            "/AutoUpdateStream=LTSR"
            "/EnableCEIP=False"
            "/log `"$($Script:LogPath).citrix.log`""
        )

        Write-AccuroPrerequisitesLog "Running Citrix installer with arguments: $($arguments -join ' ')"

        # Direct process execution with timeout
        try {
            Write-AccuroPrerequisitesLog "Starting Citrix installation process..."
            $process = Start-Process -FilePath $citrixInstaller -ArgumentList $arguments -PassThru -Wait -NoNewWindow
            $exitCode = $process.ExitCode
            Write-AccuroPrerequisitesLog "Initial process completed with exit code: $exitCode"

            # Additional wait for any child processes
            $maxWait = 300 # 5 minutes
            $waited = 0
            while ($waited -lt $maxWait) {
                $citrixProcesses = Get-Process | Where-Object { 
                    $_.ProcessName -match "Citrix|Receiver|Workspace" -and
                    $_.Id -ne $pid 
                }
                
                if (-not $citrixProcesses) {
                    Write-AccuroPrerequisitesLog "No remaining Citrix processes found. Installation complete."
                    break
                }
                
                Write-AccuroPrerequisitesLog "Waiting for Citrix processes to complete... ($waited seconds elapsed)"
                Start-Sleep -Seconds 10
                $waited += 10
            }

            if ($waited -ge $maxWait) {
                Write-AccuroPrerequisitesLog "Timeout waiting for Citrix processes to complete" -Level Warning
            }

            # Verify installation regardless of timeout
            if (Test-Path "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe") {
                Write-AccuroPrerequisitesLog "Citrix core files detected after installation"
                if ($exitCode -eq 0) {
                    $exitCode = 0  # Confirm success
                }
            }
            else {
                Write-AccuroPrerequisitesLog "Citrix core files not found after installation" -Level Error
                $exitCode = 1603  # Force error if files aren't present
            }
        }
        catch {
            Write-AccuroPrerequisitesLog "Process execution failed: $_" -Level Error
            $exitCode = 1603
        }

        Write-AccuroPrerequisitesLog "Installation process completed with exit code: $exitCode"

        # Check process exit code with proper error messages
        switch ($exitCode) {
            0 { 
                Write-AccuroPrerequisitesLog "Citrix Workspace installed successfully"
                # Wait a moment for files to settle
                Start-Sleep -Seconds 10
                
                # Verify installation through multiple methods
                $verificationPassed = $false
                
                # 1. Check registry
                $regCheck = Get-ItemProperty "HKLM:\Software\Citrix\Install\Receiver" -ErrorAction SilentlyContinue
                if ($regCheck) {
                    Write-AccuroPrerequisitesLog "Registry verification passed. Version: $($regCheck.Version)"
                    $verificationPassed = $true
                }
                
                # 2. Check file existence
                $citrixPath = "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe"
                if (Test-Path $citrixPath) {
                    $fileVersion = (Get-Item $citrixPath).VersionInfo.FileVersion
                    Write-AccuroPrerequisitesLog "File verification passed. Executable version: $fileVersion"
                    $verificationPassed = $true
                }
                
                # 3. Check service
                $service = Get-Service "CitrixWorkspaceUpdateSvc" -ErrorAction SilentlyContinue
                if ($service) {
                    Write-AccuroPrerequisitesLog "Service verification passed. Service status: $($service.Status)"
                    $verificationPassed = $true
                }

                if ($verificationPassed) {
                    return $true
                }
                else {
                    Write-AccuroPrerequisitesLog "Installation verification failed" -Level Error
                    return $false
                }
            }
            1603 { 
                Write-AccuroPrerequisitesLog "Citrix Workspace installation failed with fatal error (1603)" -Level Error
                return $false 
            }
            40008 { 
                Write-AccuroPrerequisitesLog "Citrix Workspace is already installed (40008)" -Level Warning
                return $true 
            }
            3010 { 
                Write-AccuroPrerequisitesLog "Citrix Workspace installed successfully - Reboot required (3010)" -Level Warning
                return $true 
            }
            1641 { 
                Write-AccuroPrerequisitesLog "Citrix Workspace installed successfully - Reboot required (1641)" -Level Warning
                return $true 
            }
            default {
                Write-AccuroPrerequisitesLog "Citrix Workspace installation failed with exit code: $exitCode" -Level Error
                return $false
            }
        }
    }
    catch {
        Write-AccuroPrerequisitesLog "Error installing Citrix Workspace: $_" -Level Error
        return $false
    }
    finally {
        # Enhanced process cleanup
        Write-AccuroPrerequisitesLog "Performing thorough process cleanup..."
        Get-Process | Where-Object { 
            $_.ProcessName -match "Citrix|Receiver|Workspace" -and
            $_.Id -ne $pid 
        } | ForEach-Object {
            Write-AccuroPrerequisitesLog "Stopping process: $($_.ProcessName) (ID: $($_.Id))"
            $_ | Stop-Process -Force -ErrorAction SilentlyContinue
        }

        # Wait a moment before cleanup to ensure process is fully terminated
        Start-Sleep -Seconds 5
        if (Test-Path $citrixInstaller) {
            Remove-Item -Path $citrixInstaller -Force -ErrorAction SilentlyContinue
            Write-AccuroPrerequisitesLog "Cleaned up Citrix installer file"
        }
    }
}

function Install-ScrewDriversClient {
    # Check if already installed
    $screwDriversPath = "${env:ProgramFiles(x86)}\ThinPrint\ScrewDrivers Client\ScrewDrivers.exe"
    if (Test-Path $screwDriversPath) {
        $version = (Get-Item $screwDriversPath).VersionInfo.FileVersion
        Write-AccuroPrerequisitesLog "ScrewDrivers Client is already installed (Version: $version)" -Level Information
        return $true
    }

    $screwDriversUrl = "https://www.cloudwerx.com/update/files/ScrewDriversClient_6.6.1.17374_x64.msi"
    $screwDriversInstaller = Join-Path $Script:DownloadPath "ScrewDriversClient.msi"

    try {
        Write-AccuroPrerequisitesLog "Starting ScrewDrivers Client download..."
        $downloadSuccess = Start-FileDownloadWithRetry -Source $screwDriversUrl -Destination $screwDriversInstaller
        
        if (-not $downloadSuccess) {
            Write-AccuroPrerequisitesLog "Failed to download ScrewDrivers Client installer" -Level Error
            return $false
        }

        Write-AccuroPrerequisitesLog "Installing ScrewDrivers Client..."
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$screwDriversInstaller`" /qn /norestart" -Wait -PassThru

        if ($process.ExitCode -eq 0) {
            Write-AccuroPrerequisitesLog "ScrewDrivers Client installed successfully"
            return $true
        }
        else {
            Write-AccuroPrerequisitesLog "ScrewDrivers Client installation failed with exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    }
    catch {
        Write-AccuroPrerequisitesLog "Error installing ScrewDrivers Client: $_" -Level Error
        return $false
    }
    finally {
        if (Test-Path $screwDriversInstaller) {
            Remove-Item -Path $screwDriversInstaller -Force
            Write-AccuroPrerequisitesLog "Cleaned up ScrewDrivers installer file"
        }
    }
}

function Install-CloudwerxPlugin {
    # Check if already installed
    $cloudwerxPath = "${env:ProgramFiles(x86)}\Cloudwerx\Cloudwerx.exe"
    if (Test-Path $cloudwerxPath) {
        $version = (Get-Item $cloudwerxPath).VersionInfo.FileVersion
        Write-AccuroPrerequisitesLog "Cloudwerx Plugin is already installed (Version: $version)" -Level Information
        return $true
    }

    $cloudwerxUrl = "https://www.cloudwerx.com/update/files/cloudwerx-setup.zip"
    $cloudwerxZip = Join-Path $Script:DownloadPath "cloudwerx-setup.zip"
    $cloudwerxExtracted = Join-Path $Script:DownloadPath "cloudwerx"

    try {
        Write-AccuroPrerequisitesLog "Starting Cloudwerx Plugin download..."
        $downloadSuccess = Start-FileDownloadWithRetry -Source $cloudwerxUrl -Destination $cloudwerxZip
        
        if (-not $downloadSuccess) {
            Write-AccuroPrerequisitesLog "Failed to download Cloudwerx Plugin installer" -Level Error
            return $false
        }

        Write-AccuroPrerequisitesLog "Extracting Cloudwerx Plugin..."
        Expand-Archive -Path $cloudwerxZip -DestinationPath $cloudwerxExtracted -Force

        Write-AccuroPrerequisitesLog "Installing Cloudwerx Plugin..."
        $installer = Get-ChildItem -Path $cloudwerxExtracted -Filter "*.exe" -Recurse | Select-Object -First 1
        if ($installer) {
            $process = Start-Process -FilePath $installer.FullName -ArgumentList "/S" -Wait -PassThru -NoNewWindow

            if ($process.ExitCode -eq 0) {
                Write-AccuroPrerequisitesLog "Cloudwerx Plugin installed successfully"
                return $true
            }
            else {
                Write-AccuroPrerequisitesLog "Cloudwerx Plugin installation failed with exit code: $($process.ExitCode)" -Level Error
                return $false
            }
        }
        else {
            Write-AccuroPrerequisitesLog "Could not find Cloudwerx Plugin installer in the extracted files" -Level Error
            return $false
        }
    }
    catch {
        Write-AccuroPrerequisitesLog "Error installing Cloudwerx Plugin: $_" -Level Error
        return $false
    }
    finally {
        # Cleanup downloaded and extracted files
        if (Test-Path $cloudwerxZip) {
            Remove-Item -Path $cloudwerxZip -Force
            Write-AccuroPrerequisitesLog "Cleaned up Cloudwerx zip file"
        }
        if (Test-Path $cloudwerxExtracted) {
            Remove-Item -Path $cloudwerxExtracted -Recurse -Force
            Write-AccuroPrerequisitesLog "Cleaned up Cloudwerx extracted files"
        }
    }
}

function Complete-Installation {
    # Clean up downloaded files
    if (Test-Path $Script:DownloadPath) {
        Remove-Item -Path $Script:DownloadPath -Recurse -Force
        Write-AccuroPrerequisitesLog "Cleaned up temporary files"
    }

    if (Test-PendingReboot) {
        Write-AccuroPrerequisitesLog "Installation complete. A system reboot is recommended." -Level Warning
    }
    else {
        Write-AccuroPrerequisitesLog "Installation complete. No reboot required."
    }
}

# Main installation process
try {
    Initialize-Installation

    Write-AccuroPrerequisitesLog "Starting parallel installation of all components..."
    
    # Create installation script block with status reporting
    $installScriptBlock = {
        param($installFunction, $downloadPath, $logPath, $componentName)

        # Import the installation function
        $function:installerFunc = $installFunction

        # Define Write-AccuroPrerequisitesLog function
        function Write-AccuroPrerequisitesLog {
            param(
                [Parameter(Mandatory = $true)]
                [string]$Message,
                [Parameter()]
                [ValidateSet('Information', 'Warning', 'Error')]
                [string]$Level = 'Information'
            )

            $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
            $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
            $LineFormat = "$componentName - $Message", $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "AccuroPrerequisites_Install", $Level
            $Line = $Line -f $LineFormat

            # Create a mutex for thread-safe file access
            $mutex = New-Object System.Threading.Mutex($false, "Global\AccuroPrerequisitesLogMutex")
            try {
                $mutex.WaitOne() | Out-Null
                Add-Content -Value $Line -Path $logPath -Encoding UTF8
            }
            finally {
                $mutex.ReleaseMutex()
            }
            Write-Host "$componentName - $Message"
        }

        # Define Start-FileDownloadWithRetry function
        function Start-FileDownloadWithRetry {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$Source,
                [Parameter(Mandatory = $true)]
                [string]$Destination,
                [Parameter(Mandatory = $false)]
                [int]$MaxRetries = 3
            )

            $attempt = 0
            $success = $false

            while ($attempt -lt $MaxRetries -and -not $success) {
                try {
                    $attempt++
                    Write-AccuroPrerequisitesLog "Downloading... Attempt $attempt" -Level Information

                    # Try WebClient first
                    $webClient = [System.Net.WebClient]::new()
                    $webClient.DownloadFile($Source, $Destination)
                    
                    if (Test-Path $Destination) {
                        $fileInfo = Get-Item $Destination
                        if ($fileInfo.Length -gt 0) {
                            Write-AccuroPrerequisitesLog "Download completed successfully" -Level Information
                            $success = $true
                        }
                        else {
                            Write-AccuroPrerequisitesLog "Download failed: Empty file" -Level Error
                            throw "Download failed: Empty file"
                        }
                    }
                    else {
                        Write-AccuroPrerequisitesLog "Download failed: File not found" -Level Error
                        throw "Download failed: File not found"
                    }
                }
                catch {
                    Write-AccuroPrerequisitesLog "WebClient download failed: $($_.Exception.Message)" -Level Warning
                    if ($attempt -eq $MaxRetries) {
                        Write-AccuroPrerequisitesLog "Trying BITS as fallback..." -Level Warning
                        try {
                            Start-BitsTransfer -Source $Source -Destination $Destination -ErrorAction Stop
                            
                            if (Test-Path $Destination) {
                                $fileInfo = Get-Item $Destination
                                if ($fileInfo.Length -gt 0) {
                                    Write-AccuroPrerequisitesLog "Download completed via BITS" -Level Information
                                    $success = $true
                                }
                                else {
                                    Write-AccuroPrerequisitesLog "BITS download failed: Empty file" -Level Error
                                    throw "BITS download failed: Empty file"
                                }
                            }
                            else {
                                Write-AccuroPrerequisitesLog "BITS download failed: File not found" -Level Error
                                throw "BITS download failed: File not found"
                            }
                        }
                        catch {
                            Write-AccuroPrerequisitesLog "All download attempts failed" -Level Error
                            throw "All download attempts failed"
                        }
                    }
                    else {
                        Start-Sleep -Seconds 5
                    }
                }
            }

            return $success
        }

        # Set script-level variables
        $Script:DownloadPath = $downloadPath
        $Script:LogPath = $logPath

        Write-AccuroPrerequisitesLog "Starting installation process" -Level Information
        
        # Execute the passed installation function
        $result = & installerFunc
        
        Write-AccuroPrerequisitesLog "Installation process completed with result: $result" -Level Information
        return $result
    }
    
    # Start all installations in parallel with required dependencies
    $jobs = @(
        @{
            Name = 'Citrix'
            Job = Start-Job -ScriptBlock $installScriptBlock `
                -ArgumentList ${function:Install-CitrixWorkspace}, $Script:DownloadPath, $Script:LogPath, "Citrix"
            Timeout = 60  # Back to 60 seconds since that's sufficient
            ForceStop = $true
        },
        @{
            Name = 'ScrewDrivers'
            Job = Start-Job -ScriptBlock $installScriptBlock `
                -ArgumentList ${function:Install-ScrewDriversClient}, $Script:DownloadPath, $Script:LogPath, "ScrewDrivers"
            Timeout = 300  # 5 minutes timeout
            ForceStop = $false
        },
        @{
            Name = 'Cloudwerx'
            Job = Start-Job -ScriptBlock $installScriptBlock `
                -ArgumentList ${function:Install-CloudwerxPlugin}, $Script:DownloadPath, $Script:LogPath, "Cloudwerx"
            Timeout = 300  # 5 minutes timeout
            ForceStop = $false
        }
    )

    Write-AccuroPrerequisitesLog "Waiting for installations to complete..."

    # Monitor all jobs simultaneously with improved process tracking
    $startTime = Get-Date
    $results = @{}

    while ($jobs.Where({ $_.Job.State -eq 'Running' })) {
        foreach ($jobInfo in $jobs.Where({ $_.Job.State -eq 'Running' })) {
            $elapsed = ((Get-Date) - $startTime).TotalSeconds
            
            # Check if job has exceeded its timeout
            if ($elapsed -ge $jobInfo.Timeout) {
                Write-AccuroPrerequisitesLog "$($jobInfo.Name) installation timed out after $($jobInfo.Timeout) seconds." -Level Warning
                
                if ($jobInfo.ForceStop) {
                    # Enhanced force stop for Citrix with installation check
                    if ($jobInfo.Name -eq 'Citrix') {
                        # Check if Citrix is actually installed before declaring failure
                        $citrixInstalled = $false
                        
                        # Check core file
                        if (Test-Path "${env:ProgramFiles(x86)}\Citrix\ICA Client\wfica32.exe") {
                            Write-AccuroPrerequisitesLog "Citrix core files found, checking registry..."
                            $regCheck = Get-ItemProperty "HKLM:\Software\Citrix\Install\Receiver" -ErrorAction SilentlyContinue
                            if ($regCheck) {
                                Write-AccuroPrerequisitesLog "Citrix appears to be installed successfully (Version: $($regCheck.Version))"
                                $citrixInstalled = $true
                            }
                        }

                        Write-AccuroPrerequisitesLog "Performing thorough Citrix process cleanup..."
                        Get-Process | Where-Object { 
                            $_.ProcessName -match "Citrix|Receiver|Workspace|ICA|SSON" -and
                            $_.Id -ne $pid 
                        } | ForEach-Object {
                            Write-AccuroPrerequisitesLog "Force stopping process: $($_.ProcessName) (ID: $($_.Id))"
                            try {
                                $_ | Stop-Process -Force -ErrorAction Stop
                                Write-AccuroPrerequisitesLog "Successfully stopped process: $($_.ProcessName)"
                            }
                            catch {
                                Write-AccuroPrerequisitesLog "Failed to stop process $($_.ProcessName): $_" -Level Warning
                            }
                        }

                        # Set the result based on installation check
                        $results[$jobInfo.Name] = $citrixInstalled
                    }
                }
                
                Stop-Job -Job $jobInfo.Job
                if (-not $results.ContainsKey($jobInfo.Name)) {
                    $results[$jobInfo.Name] = $false
                }
            }
        }
        
        Start-Sleep -Seconds 5
    }

    # Process results for jobs that completed normally
    foreach ($jobInfo in $jobs.Where({ $_.Job.State -eq 'Completed' })) {
        $results[$jobInfo.Name] = Receive-Job -Job $jobInfo.Job -ErrorAction SilentlyContinue
    }

    # Cleanup jobs
    $jobs | ForEach-Object { Remove-Job -Job $_.Job -Force -ErrorAction SilentlyContinue }

    Complete-Installation

    # Log detailed results
    Write-AccuroPrerequisitesLog "Installation Results Summary:" -Level Information
    foreach ($component in $results.Keys) {
        $status = if ($results[$component]) { "succeeded" } else { "failed" }
        Write-AccuroPrerequisitesLog "$component installation $status" -Level $(if ($results[$component]) { "Information" } else { "Warning" })
    }

    if (-not ($results.Values -contains $true)) {
        Write-AccuroPrerequisitesLog "All installations failed. Please check the log file at $Script:LogPath" -Level Error
        exit 1
    }
    
    exit 0
}
catch {
    Write-AccuroPrerequisitesLog "An unexpected error occurred: $_" -Level Error
    exit 1
}