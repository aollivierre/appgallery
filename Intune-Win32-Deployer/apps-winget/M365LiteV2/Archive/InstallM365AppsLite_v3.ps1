<#
.SYNOPSIS
  Script to install M365 Apps as a Win32 App

.DESCRIPTION
    Script to install Office as a Win32 App during Autopilot by downloading the latest Office setup exe from evergreen url
    Running Setup.exe from downloaded files with provided config.xml file. 

.EXAMPLE
    Without external XML (Requires configuration.xml in the package)
    powershell.exe -executionpolicy bypass -file InstallM365Apps.ps1
    With external XML (Requires XML to be provided by URL)  
    powershell.exe -executionpolicy bypass -file InstallM365Apps.ps1 -XMLURL "https://mydomain.com/xmlfile.xml"

.NOTES
    Version:        1.2
    Author:         Jan Ketil Skanke
    Contact:        @JankeSkanke
    Creation Date:  01.07.2021
    Updated:        (2022-23-11)
    Version history:
        1.0.0 - (2022-23-10) Script released 
        1.1.0 - (2022-25-10) Added support for External URL as parameter 
        1.2.0 - (2022-23-11) Moved from ODT download to Evergreen url for setup.exe 
        1.2.1 - (2022-01-12) Adding function to validate signing on downloaded setup.exe
#>
#region parameters
# [CmdletBinding()]
# Param (
#     [Parameter(Mandatory = $false)]
#     [string]$XMLUrl
# )
#endregion parameters
#Region Functions


$XMLUrl = 'https://deploymentconfigstorage.blob.core.windows.net/deploymentconfig/9bf01198-4a80-42b2-b334-5587c6861658/0334c2b5-4d23-4dc9-9264-c42b7c68d160.xml?sv=2018-11-09&sr=b&sig=IuToeiHMiBrEnbM7GUcdrrjJerELWuvBWTfv3sU5S00%3D&st=2023-05-16T22%3A40%3A11Z&se=2025-05-15T22%3A45%3A11Z&sp=r'

#Endregion Functions

#Region Initialisations
#Endregion Initialisations

#Initate Install

#Attempt Cleanup of SetupFolder
# if (Test-Path "$($env:SystemRoot)\Temp\OfficeSetup") {
#     Remove-Item -Path "$($env:SystemRoot)\Temp\OfficeSetup" -Recurse -Force -ErrorAction SilentlyContinue
# }

# $SetupFolder = (New-Item -ItemType "directory" -Path "$($env:SystemRoot)\Temp" -Name OfficeSetup -Force).FullName
$SetupFolder = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

try {
    #Download latest Office (ODT) setup.exe
    $SetupEverGreenURL = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
    # Start-DownloadFile -URL $SetupEverGreenURL -Path $SetupFolder -Name "setup.exe"

    # Start-BitsTransfer -Source "http://example.com/file.zip" -Destination "C:\path\to\save\file.zip"

    Start-BitsTransfer -Source $SetupEverGreenURL -Destination "$SetupFolder\setup.exe"

    
    try {
        #Start install preparations
        $SetupFilePath = Join-Path -Path $SetupFolder -ChildPath "setup.exe"
        if (-Not (Test-Path $SetupFilePath)) {
            Throw "Error: Setup file not found"
        }
        try {
            #Prepare Office Installation
            $OfficeCR2Version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$($SetupFolder)\setup.exe").FileVersion 
            # if (Invoke-FileCertVerification -FilePath $SetupFilePath){
            #Check if XML URL is provided, if true, use that instead of trying local XML in package
                if ($XMLUrl) {
                    try {
                        #Attempt to download file from External Source
                        # Start-DownloadFile -URL $XMLURL -Path $SetupFolder -Name "configuration.xml"
                        Start-BitsTransfer -Source $XMLURL -Destination "$SetupFolder\configuration.xml"
                    }
                    catch [System.Exception] {
                        exit 1
                    }
                }
                else {
                    #Local configuration file only 
                    Copy-Item "$($PSScriptRoot)\configuration.xml" $SetupFolder -Force -ErrorAction Stop
                }
                #Starting Office setup with configuration file               
                Try {
                    #Running office installer
                    $OfficeInstall = Start-Process $SetupFilePath -ArgumentList "/configure $($SetupFolder)\configuration.xml" -Wait -PassThru -ErrorAction Stop
                }
                catch [System.Exception] {
                }
            # }
            else {
                Throw "Error: Unable to verify setup file signature"
            }
        }
        catch [System.Exception] {
        }
        
    }
    catch [System.Exception] {
    }
    
}
catch [System.Exception] {
}
# #Cleanup 
# if (Test-Path "$($env:SystemRoot)\Temp\OfficeSetup"){
#     Remove-Item -Path "$($env:SystemRoot)\Temp\OfficeSetup" -Recurse -Force -ErrorAction SilentlyContinue
# }
