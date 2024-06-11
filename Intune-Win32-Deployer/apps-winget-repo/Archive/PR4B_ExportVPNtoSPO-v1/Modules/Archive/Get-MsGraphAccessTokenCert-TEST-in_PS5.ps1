# # Static values for testing
# $tenantId = "b5dae566-ad8f-44e1-9929-5669f1dbb343"
# $clientId = "8230c33e-ff30-419c-a1fc-4caf98f069c9"
# $certPath = "C:\Code\appgallery\Intune-Win32-Deployer\apps-winget-repo\PR4B_ExportVPNtoSPO-v1\PR4B-ExportVPNtoSPO-v2\graphcert.pfx"
# $certPassword = "AS'XC@:9F+C64WHSM%^?"

# $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# # Load the certificate
# $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certPath, $certPassword)
# if (-not $cert) { 
#     Write-Host "Certificate not found at path: $certPath"
#     throw "Certificate not found." 
# }  

# # Create JWT assertion
# $jwtHeader = @{
#     alg = "RS256"
#     typ = "JWT"
#     x5t = [Convert]::ToBase64String($cert.GetCertHash())
# }

# $now = [System.DateTime]::UtcNow
# Write-Host "Current UTC Time: $now"

# # Calculate nbf and exp times manually
# $nbfTime = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 300)  # nbf is 5 minutes ago
# $expTime = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 3300) # exp is 55 minutes from now

# Write-Host "nbf (not before) time: $nbfTime"
# Write-Host "exp (expiration) time: $expTime"

# $jwtPayload = @{
#     aud = $tokenEndpoint
#     exp = $expTime
#     iss = $clientId
#     jti = [guid]::NewGuid().ToString()
#     nbf = $nbfTime
#     sub = $clientId
# }

# Write-Host "JWT Payload: $(ConvertTo-Json $jwtPayload -Compress)"

# $jwtHeaderJson = ($jwtHeader | ConvertTo-Json -Compress)
# $jwtPayloadJson = ($jwtPayload | ConvertTo-Json -Compress)
# $jwtHeaderEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jwtHeaderJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
# $jwtPayloadEncoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jwtPayloadJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

# $dataToSign = "$jwtHeaderEncoded.$jwtPayloadEncoded"
# $sha256 = [Security.Cryptography.SHA256]::Create()
# $hash = $sha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($dataToSign))

# $rsa = [Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
# $signature = [Convert]::ToBase64String($rsa.SignHash($hash, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

# $clientAssertion = "$dataToSign.$signature"
# $body = @{
#     client_id = $clientId
#     scope = "https://graph.microsoft.com/.default"
#     client_assertion = $clientAssertion
#     client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
#     grant_type = "client_credentials"
# }

# try {
#     Write-Host "Sending request to token endpoint: $tokenEndpoint"
#     $response = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -ContentType "application/x-www-form-urlencoded" -Body $body
#     Write-Host "Successfully obtained access token."
#     $response.access_token
# }
# catch {
#     Write-Host "Error obtaining access token: $_"
#     throw $_
# }