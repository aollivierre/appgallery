# function Get-MsGraphAccessTokenCert {
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$tenantId,
#         [Parameter(Mandatory = $true)]
#         [string]$clientId,
#         [Parameter(Mandatory = $true)]
#         [string]$certThumbprint
#     )

#     # Token endpoint
#     $tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

#     # Retrieve the certificate
#     $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $certThumbprint }
#     if (-not $cert) {
#         Write-Error "Certificate with thumbprint $certThumbprint not found."
#         return
#     }

#     # Create JWT header and payload
#     $jwtHeader = @{
#         alg = "RS256"
#         typ = "JWT"
#         x5t = [System.Convert]::ToBase64String($cert.GetCertHash())
#     }

#     $now = [System.DateTime]::UtcNow
#     $jwtPayload = @{
#         aud = $tokenEndpoint
#         exp = [System.Convert]::ToInt32($now.AddMinutes(60).Subtract([System.DateTime]::UnixEpoch).TotalSeconds)
#         iss = $clientId
#         jti = [System.Guid]::NewGuid().ToString()
#         nbf = [System.Convert]::ToInt32($now.Subtract([System.DateTime]::UnixEpoch).TotalSeconds)
#         sub = $clientId
#     }

#     # Convert header and payload to JSON
#     $jwtHeaderJson = (ConvertTo-Json $jwtHeader -Compress)
#     $jwtPayloadJson = (ConvertTo-Json $jwtPayload -Compress)

#     # Encode header and payload to Base64Url
#     $jwtHeaderEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($jwtHeaderJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
#     $jwtPayloadEncoded = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($jwtPayloadJson)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

#     $dataToSign = "$jwtHeaderEncoded.$jwtPayloadEncoded"

#     # Hash the data to sign
#     $sha256 = [System.Security.Cryptography.SHA256]::Create()
#     $hash = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($dataToSign))

#     # Get the RSA private key from the certificate
#     $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
#     if (-not $rsa) {
#         Write-Error "Failed to get RSA private key from certificate."
#         return
#     }

#     # Sign the hash with the RSA private key
#     $signature = [System.Convert]::ToBase64String($rsa.SignHash($hash, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)).TrimEnd('=').Replace('+', '-').Replace('/', '_')

#     # Create the client assertion
#     $clientAssertion = "$dataToSign.$signature"

#     # Prepare the request body
#     $body = @{
#         client_id = $clientId
#         scope = "https://graph.microsoft.com/.default"
#         client_assertion = $clientAssertion
#         client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
#         grant_type = "client_credentials"
#     }

#     # Make the HTTP request to get the token
#     try {
#         $httpClient = New-Object System.Net.Http.HttpClient
#         $content = New-Object System.Net.Http.FormUrlEncodedContent -ArgumentList (New-Object 'Collections.Generic.Dictionary[String,String]')
#         $body.GetEnumerator() | ForEach-Object { $content.Headers.Add($_.Key, $_.Value) }

#         $response = $httpClient.PostAsync($tokenEndpoint, $content).Result

#         if (-not $response.IsSuccessStatusCode) {
#             Write-Error "HTTP request failed with status code: $($response.StatusCode)"
#             return
#         }

#         $responseContent = $response.Content.ReadAsStringAsync().Result
#         $accessToken = (ConvertFrom-Json $responseContent).access_token

#         if ($accessToken) {
#             Write-Output "Access token retrieved successfully"
#             return $accessToken
#         } else {
#             Write-Error "Failed to retrieve access token, response was successful but no token was found."
#             return
#         }
#     }
#     catch {
#         Write-Error "Failed to execute HTTP request or process results: $_"
#         return
#     }
# }


# $ClientId = '8230c33e-ff30-419c-a1fc-4caf98f069c9'
# $TenantId = 'b5dae566-ad8f-44e1-9929-5669f1dbb343'
# $CertThumbprint = '9B69D19C97BCE75B4208FDE6B2A4A53141628057'

# # Example usage
# $token = Get-MsGraphAccessTokenCert -tenantId $tenantId -clientId $clientId -certThumbprint $certThumbprint
# Write-Output $token