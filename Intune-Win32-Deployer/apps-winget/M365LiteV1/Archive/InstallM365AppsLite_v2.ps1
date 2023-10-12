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
#>
#region parameters
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [string]$XMLUrl
)
#endregion parameters
#Region Functions

function Start-DownloadFile {
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$URL,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    Begin {
        $WebClient = New-Object -TypeName System.Net.WebClient
    }
    Process {
        if (-not(Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
        $WebClient.DownloadFile($URL, (Join-Path -Path $Path -ChildPath $Name))
    }
    End {
        $WebClient.Dispose()
    }
}

function Invoke-FileCertVerification {
    param(
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    $Cert = (Get-AuthenticodeSignature -FilePath $FilePath).SignerCertificate
    $CertStatus = (Get-AuthenticodeSignature -FilePath $FilePath).Status

    if ($Cert){
        if ($cert.Subject -match "O=Microsoft Corporation" -and $CertStatus -eq "Valid"){
            $chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
            $chain.Build($cert) | Out-Null
            $RootCert = $chain.ChainElements | ForEach-Object {$_.Certificate}| Where-Object {$PSItem.Subject -match "CN=Microsoft Root"}

            if (-not [string ]::IsNullOrEmpty($RootCert)){
                $TrustedRoot = Get-ChildItem -Path "Cert:\LocalMachine\Root" -Recurse | Where-Object { $PSItem.Thumbprint -eq $RootCert.Thumbprint}
                if (-not [string]::IsNullOrEmpty($TrustedRoot)){
                    Return $True
                }
                else {
                    Return $False
                }
            }
            else {
                Return $False
            }
        }
        else {
            Return $False
        }  
    }
    else {
        Return $False
    }
}

#Endregion Functions

$SetupFolder = (New-Item -ItemType "directory" -Path "$($env:SystemRoot)\Temp" -Name OfficeSetup -Force).FullName

$SetupEverGreenURL = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
Start-DownloadFile -URL $SetupEverGreenURL -Path $SetupFolder -Name "setup.exe"

$SetupFilePath = Join-Path -Path $SetupFolder -ChildPath "setup.exe"

if (-Not (Test-Path $SetupFilePath)) {
    Throw "Error: Setup file not found

}

$OfficeCR2Version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$($SetupFolder)\setup.exe").FileVersion 

if (Invoke-FileCertVerification -FilePath $SetupFilePath){

    if ($XMLUrl) {
        Start-DownloadFile -URL $XMLURL -Path $SetupFolder -Name "configuration.xml"
    }
    else {
        Copy-Item "$($PSScriptRoot)\configuration.xml" $SetupFolder -Force
    }

    $OfficeInstall = Start-Process $SetupFilePath -ArgumentList "/configure $($SetupFolder)\configuration.xml" -Wait -PassThru
}

if (Test-Path "$($env:SystemRoot)\Temp\OfficeSetup"){
    Remove-Item -Path "$($env:SystemRoot)\Temp\OfficeSetup" -Recurse -Force -ErrorAction SilentlyContinue
}

