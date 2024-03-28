function Get-DotNetVersion {
    $dotNetVersions = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
                      Get-ItemProperty -Name Version,Release -ErrorAction SilentlyContinue |
                      Where-Object { $_.PSChildName -match '^(?!S)\p{L}'} |
                      Select-Object PSChildName, Version, Release

    return $dotNetVersions
}

# Usage
# Get-DotNetVersion



function Get-VCPlusPlusVersion {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\VisualStudio\*\VC\Runtimes\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\*\VC\Runtimes\*'
    )

    $vcVersions = foreach ($path in $paths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
        Where-Object { $_.Installed -eq 1 } |
        Select-Object @{Name="Version"; Expression={$_.PSChildName}}, 
                      @{Name="Architecture"; Expression={if ($_.PSPath -like "*WOW6432Node*") {"x86"} else {"x64"}}},
                      VersionMajor, VersionMinor, Bld, VCRuntimeMinimumVersion
    }

    return $vcVersions
}

# Usage
# Get-VCPlusPlusVersion



function Install-FileHold {
    param (
        [string]$InstallerPath, # Path to the File Hold Desktop (FDA) installer
        [switch]$InstallFOC,    # Switch to decide whether to install FileHold Office Client
        [switch]$InstallBrava   # Switch to decide whether to install Brava viewer
    )

    # Check if the installer file exists
    if (-not (Test-Path -Path $InstallerPath)) {
        Write-Error "Installer file not found at path: $InstallerPath"
        return
    }

    # Construct the silent install command
    $installCommand = "$InstallerPath /S /V`"/qn"

    # Add optional parameters based on function arguments
    if ($InstallFOC) {
        $installCommand += " [FHINSTALLFOC=1]"
    } else {
        $installCommand += " [FHINSTALLFOC=0]"
    }

    if ($InstallBrava) {
        $installCommand += " [FHINSTALLBRAVACHOICE=1]"
    } else {
        $installCommand += " [FHINSTALLBRAVACHOICE=0]"
    }

    $installCommand += " [ALLUSERS=1]`"" # Install for all users

    # Execute the installation command
    try {
        Write-Host "Starting FileHold installation..."
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $installCommand" -Wait -NoNewWindow
        Write-Host "FileHold installation completed successfully."
    }
    catch {
        Write-Error "An error occurred during installation: $_"
    }
}

# Example usage:
# Install-FileHold -InstallerPath "C:\Path\To\FileHold17.0.3_Client-230607.1-230607.1.exe" -InstallFOC -InstallBrava
# Install-FileHold -InstallerPath "C:\Path\To\FileHold17.0.3_Client-230607.1-230607.1.exe" -InstallFOC
Install-FileHold -InstallerPath "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FileHold\FileHold17.0.3-Client-Installation-Kit-20230607\FileHold17.0.3-Client-Installation-Kit-20230607\FileHold17.0.3_Client-230607.1-230607.1.exe" -InstallFOC




# "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FileHold\FileHold17.0.3-Client-Installation-Kit-20230607\FileHold17.0.3-Client-Installation-Kit-20230607\FileHold17.0.3_Client-230607.1-230607.1.exe /S /V"/qn [FHINSTALLFOC=1] [FHINSTALLBRAVACHOICE=0] [ALLUSERS=1]""



# "C:\Code\CB\AppGallery\Intune-Win32-Deployer\apps-winget\FileHold\FileHold17.0.3-Client-Installation-Kit-20230607\FileHold17.0.3-Client-Installation-Kit-20230607\FileHold17.0.3_Client-230607.1-230607.1.exe" /S /V"/qn [FHINSTALLFOC=1] [FHINSTALLBRAVACHOICE=0] [ALLUSERS=1]"




# "C:\Path\To\FileHold17.0.3_Client-230607.1-230607.1.exe" /S /V"/qn [FHINSTALLFOC=1] [FHINSTALLBRAVACHOICE=0] [ALLUSERS=1]"
# "C:\Code\FileHold17.0.3_Client-230607.1-230607.1.exe" /S /V"/qn [FHINSTALLFOC=1] [FHINSTALLBRAVACHOICE=0] [ALLUSERS=1]"



# C:\Code\FileHold17.0.3_Client-230607.1-230607.1.exe /S /V"/qn [FHINSTALLFOC=1] [FHINSTALLBRAVACHOICE=0] [ALLUSERS=1]"


#the following worked but interactively
# C:\f.exe /S /V



# C:\f.exe /S /V"/qn [ALLUSERS=1]"


C:\f.exe /S /V"/qn ALLUSERS=1"

C:\f.exe /S /V/qn /x