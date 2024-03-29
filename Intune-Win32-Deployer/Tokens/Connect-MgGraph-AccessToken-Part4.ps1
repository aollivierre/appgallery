$clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
$tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

$refreshToken ='0.Axxxxxxxxxxxxxxxxxxx'


# Token endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Prepare the request body. Exclude 'client_secret' if your app is a public client.
$body = @{
    client_id     = $clientId
    grant_type    = "refresh_token"
    refresh_token = $refreshToken
    # Uncomment the next line if your application is a confidential client
    #client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"  # Adjust this scope according to your needs
}

# Make the POST request
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Output the new access token and refresh token
Write-Host "New Access Token: $($response.access_token)"
# Some authorization servers might not return a new refresh token every time you refresh an access token
if ($response.refresh_token) {
    # Write-Host "New Refresh Token: $($response.refresh_token)" uncomment for debugging
}


$accessTokenString = $response.access_token

# Assuming your access token is stored in a variable named $accessTokenString
# Convert the plain string token to a SecureString
$secureAccessToken = $accessTokenString | ConvertTo-SecureString -AsPlainText -Force

# Use the SecureString access token to connect
Connect-MgGraph -AccessToken $secureAccessToken