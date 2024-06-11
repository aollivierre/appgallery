# function Convert-WindowsPathToLinuxPath {
#     <#
# .SYNOPSIS
#     Converts a Windows file path to a Linux file path.

# .DESCRIPTION
#     This function takes a Windows file path as input and converts it to a Linux file path.
#     It assumes a mapping from a base Windows path to a base Linux path which can be customized.

# .PARAMETER WindowsPath
#     The full file path in Windows format that needs to be converted.

# .PARAMETER WindowsBasePath
#     The base directory path in Windows from which the relative path begins. Default is 'C:\Code'.

# .PARAMETER LinuxBasePath
#     The base directory path in Linux where the Windows base path is mapped. Default is '/usr/src'.

# .EXAMPLE
#     PS> Convert-WindowsPathToLinuxPath -WindowsPath 'C:\Code\CB\Entra\ARH\Get-EntraConnectSyncErrorsfromEntra copy.ps1'
#     Returns '/usr/src/CB/Entra/ARH/Get-EntraConnectSyncErrorsfromEntra copy.ps1'

# #>
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$WindowsPath,

#         [string]$WindowsBasePath = 'C:\Code',

#         [string]$LinuxBasePath = '/usr/src'
#     )

#     Begin {
#         Write-Host "Starting the path conversion process..."
#     }

#     Process {
#         try {
#             if (-not $WindowsPath.StartsWith($WindowsBasePath, [System.StringComparison]::OrdinalIgnoreCase)) {
#                 throw "The provided Windows path does not start with the expected base path: $WindowsBasePath"
#             }

#             Write-Host "Input Windows Path: $WindowsPath"
#             Write-Host "Converting to relative path..."

#             # Remove the Windows base path and replace backslashes with forward slashes
#             $relativePath = $WindowsPath.Substring($WindowsBasePath.Length).Replace('\', '/')

#             # Construct the full Linux path
#             $linuxPath = $LinuxBasePath + $relativePath
#             Write-Host "Converted Linux Path: $linuxPath"

#             return $linuxPath
#         }
#         catch {
#             Write-Host "Error during conversion: $_"
#             throw
#         }
#     }

#     End {
#         Write-Host "Path conversion completed."
#     }
# }


# function Get-MsGraphAccessTokenCert {
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$tenantId,
#         [Parameter(Mandatory = $true)]
#         [string]$clientId,
#         [Parameter(Mandatory = $true)]
#         [string]$certPath,
#         [Parameter(Mandatory = $true)]
#         [string]$certPassword
#     )

#     $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

#     # Load the certificate
#     $cert = if ($PSVersionTable.Platform -eq 'Unix') {
#         # Load the certificate from file on Unix (Linux)
#         [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certPath, $certPassword)
#     } else {
#         # Retrieve the certificate from the Windows cert store
#         Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $certPath }
#     }

#     if (-not $cert) { throw "Certificate not found." }

#     # Create JWT assertion
#     $jwtHeader = @{ alg = "RS256"; typ = "JWT"; x5t = [Convert]::ToBase64String($cert.GetCertHash()) }
#     $now = [System.DateTime]::UtcNow
#     $jwtPayload = @{
#         aud = $tokenEndpoint
#         exp = [int][double](Get-Date (Get-Date).AddMinutes(60) -UFormat %s)
#         iss = $clientId
#         jti = [guid]::NewGuid().ToString()
#         nbf = [int][double](Get-Date (Get-Date) -UFormat %s)
#         sub = $clientId
#     }

#     $jwtHeaderJson = ($jwtHeader | ConvertTo-Json -Compress)
#     $jwtPayloadJson = ($jwtPayload | ConvertTo-Json -Compress)
#     $jwtHeaderEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jwtHeaderJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
#     $jwtPayloadEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jwtPayloadJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

#     $dataToSign = "$jwtHeaderEncoded.$jwtPayloadEncoded"
#     $sha256 = [Security.Cryptography.SHA256]::Create()
#     $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($dataToSign))

#     $rsa = [Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
#     $signature = [Convert]::ToBase64String($rsa.SignHash($hash, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

#     $clientAssertion = "$dataToSign.$signature"
#     $body = @{
#         client_id = $clientId
#         scope = "https://graph.microsoft.com/.default"
#         client_assertion = $clientAssertion
#         client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
#         grant_type = "client_credentials"
#     }

#     $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Body $body
#     return $response.access_token
# }

# # Example usage
# $clientId = '8230c33e-ff30-419c-a1fc-4caf98f069c9'
# $tenantId = 'b5dae566-ad8f-44e1-9929-5669f1dbb343'




# $certwinPath = 'C:\Code\Unified365toolbox\Graph\graphcert.pfx'
# $certlinuxPath = Convert-WindowsPathToLinuxPath -WindowsPath $certwinPath
# Write-Host "Linux path: $certlinuxPath"
# # $certPath = 'C:\Code\Unified365toolbox\Graph\graphcert.pfx'
# $certPassword = "AS'XC@:9F+C64WHSM%^?"

# $token = Get-MsGraphAccessTokenCert -tenantId $tenantId -clientId $clientId -certPath $certlinuxPath -certPassword $certPassword
# Write-Output $token
