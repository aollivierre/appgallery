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
#     $cert = Load-Certificate -CertPath $certPath -CertPassword $certPassword

#     if (-not $cert) { 
#         Write-EnhancedLog -Message "Certificate not found at path: $certPath" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#         throw "Certificate not found." 
#     }  

#     # Create JWT assertion
#     $jwtHeader = @{
#         alg = "RS256"
#         typ = "JWT"
#         x5t = [Convert]::ToBase64String($cert.GetCertHash())
#     }

#     $now = [System.DateTime]::UtcNow
#     Write-EnhancedLog -Message "Current UTC Time: $now" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

#     $nbfTime = [int][double](Get-Date (Get-Date).AddMinutes(-5) -UFormat %s)
#     $expTime = [int][double](Get-Date (Get-Date).AddMinutes(55) -UFormat %s)
    
#     Write-EnhancedLog -Message "nbf (not before) time: $nbfTime ($([System.DateTime]::UnixEpoch.AddSeconds($nbfTime)))" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#     Write-EnhancedLog -Message "exp (expiration) time: $expTime ($([System.DateTime]::UnixEpoch.AddSeconds($expTime)))" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
    
#     $jwtPayload = @{
#         aud = $tokenEndpoint
#         exp = $expTime
#         iss = $clientId
#         jti = [guid]::NewGuid().ToString()
#         nbf = $nbfTime
#         sub = $clientId
#     }
    
#     Write-EnhancedLog -Message "JWT Payload: $(ConvertTo-Json $jwtPayload -Compress)" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)

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

#     try {
#         Write-EnhancedLog -Message "Sending request to token endpoint: $tokenEndpoint" -Level "INFO" -ForegroundColor ([ConsoleColor]::Cyan)
#         $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Body $body
#         Write-EnhancedLog -Message "Successfully obtained access token." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
#         return $response.access_token
#     }
#     catch {
#         Write-EnhancedLog -Message "Error obtaining access token: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
#         throw $_
#     }
# }








