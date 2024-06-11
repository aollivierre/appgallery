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

#     $cert = Load-Certificate -CertPath $certPath -CertPassword $certPassword

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

# $certPath = 'C:\Code\Unified365toolbox\Graph\graphcert.pfx'
# $certPassword = "Somepassword"

# $token = Get-MsGraphAccessTokenCert -tenantId $tenantId -clientId $clientId -certPath $certPath -certPassword $certPassword
# Write-Output $token