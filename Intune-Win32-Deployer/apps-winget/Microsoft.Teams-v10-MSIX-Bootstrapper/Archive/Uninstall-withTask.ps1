function Write-Log {
    param (
        [string]$Message
    )
    Write-Host $Message
}

function Write-ErrorAndExit {
    param (
        [string]$Message
    )
    Write-Error $Message
    exit 1
}



function Invoke-WithMaxAttempts {
    param (
        [ScriptBlock]$Operation,
        [int]$MaxAttempts = 10
    )

    $attempt = 0
    $success = $false

    while ($attempt -lt $MaxAttempts -and -not $success) {
        try {
            # Invoke the operation script block
            . $Operation
            $success = $true
            Write-Log "Operation succeeded on attempt #$($attempt + 1)"
        } catch {
            Write-Log "Attempt #$($attempt + 1) failed. Error: $_"
            Start-Sleep -Seconds 2 # Wait before retrying
        }

        $attempt++
    }

    if (-not $success) {
        Write-Log "Operation failed after $MaxAttempts attempts."
        exit 1
    }
}


function KillTeamsProcesses {
    $teamsProcesses = Get-Process -Name "ms-teams" -ErrorAction SilentlyContinue
    if ($teamsProcesses) {
        Write-Log "Attempting to kill Microsoft Teams processes."
        $teamsProcesses | ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
    } else {
        Write-Log "No Microsoft Teams processes found."
        # Indicate success to prevent unnecessary retries
        return $true
    }
}




$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
function Invoke-RemediationAndRemoveTask {
    # Assuming this function is in the same directory as the scripts,
    # or you have set the working directory to the script root.
    # Define the paths to the scripts
    $remediationScriptPath = Join-Path -Path $scriptRoot -ChildPath "installtask.ps1"
    # $removeTaskScriptPath = Join-Path -Path $scriptRoot -ChildPath "removetask.ps1"

    # Execute the remediation script
    if (Test-Path -Path $remediationScriptPath -PathType Leaf) {
        Write-Output "Running remediation script..."
        & $remediationScriptPath
    } else {
        Write-Warning "Remediation script not found at path: $remediationScriptPath"
    }

    # # Execute the remove task script
    # if (Test-Path -Path $removeTaskScriptPath -PathType Leaf) {
    #     Write-Output "Running remove task script..."
    #     & $removeTaskScriptPath
    # } else {
    #     Write-Warning "Remove task script not found at path: $removeTaskScriptPath"
    # }
}


function Start-TeamsUninstaller {
    Start-Process -FilePath ".\teamsbootstrapper.exe" -ArgumentList "-x" -Wait -WindowStyle Hidden
}

function Remove-ProvisionedTeamsPackages {
    $teamsProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like "*MSTeams*"
    foreach ($package in $teamsProvisionedPackages) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $package.PackageName
            Write-Log "Successfully removed provisioned package: $($package.DisplayName)"
        } catch {
            Write-Log "Failed to remove provisioned package: $($package.DisplayName). Error: $_"
        }
    }
}


function Remove-CurrentUserTeamsPackage {
    $teamsPackage = Get-AppxPackage | Where-Object { $_.Name -like "*MSTeams*" }
    if ($teamsPackage) {
        Remove-AppxPackage -Package $teamsPackage.PackageFullName
    }
}




function CleanupTeamsDirectories {
    param (
        [string[]]$PathsToSearch,
        [string]$TeamsPattern = "MSTeams_*_x64__*"
    )

    foreach ($basePath in $PathsToSearch) {
        $teamsItems = Get-ChildItem -Path $basePath -Filter $TeamsPattern -Recurse -ErrorAction SilentlyContinue -Force

        if ($teamsItems.Count -gt 0) {
            foreach ($item in $teamsItems) {
                $itemPath = $item.FullName
                Write-Log "Processing item: $itemPath"
                takeown /f "$itemPath" /r /d y | Out-Null
                icacls "$itemPath" /grant "SYSTEM:(F)" /t /c | Out-Null
                try {
                    Remove-Item -Path "$itemPath" -Recurse -Force -ErrorAction Stop
                    Write-Log "Successfully removed: $itemPath"
                } catch {
                    Write-Log "Failed to remove: $itemPath. Error: $_"
                }
            }
        } else {
            Write-Log "No Microsoft Teams items found under $basePath."
        }
    }
}



# KillTeamsProcesses

# # Define base paths for cleanup
# $pathsToSearch = @("C:\ProgramData", "C:\Program Files\WindowsApps")

# # Start the Teams uninstaller
# Start-TeamsUninstaller

# # Remove provisioned Teams packages
# Remove-ProvisionedTeamsPackages

# # Remove the current user Teams package
# Remove-CurrentUserTeamsPackage

# # Cleanup Teams directories
# CleanupTeamsDirectories -PathsToSearch $pathsToSearch








# Define other necessary functions here (e.g., Start-TeamsUninstaller, Remove-ProvisionedTeamsPackages, etc.)

# Use Invoke-WithMaxAttempts to ensure Teams processes are terminated before proceeding
Invoke-WithMaxAttempts -Operation {
    KillTeamsProcesses
}



# Invoke-WithMaxAttempts -Operation {
#     Invoke-RemediationAndRemoveTask
# }


# Proceed with other operations, potentially using Invoke-WithMaxAttempts for them as well
Invoke-WithMaxAttempts -Operation {
    Start-TeamsUninstaller
}
Invoke-WithMaxAttempts -Operation {
    Remove-ProvisionedTeamsPackages
}
Invoke-WithMaxAttempts -Operation {
    Remove-CurrentUserTeamsPackage
}
Invoke-WithMaxAttempts -Operation {
    CleanupTeamsDirectories -PathsToSearch @("C:\ProgramData", "C:\Program Files\WindowsApps")
}