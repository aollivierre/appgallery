$clientId = "xxxxxxxxxxxx-84e936411eb7"
# $clientSecret = ""
# $tenantName = "bellwoodscentres.onmicrosoft.com"
$tenantID = "xxxxxxxxx-c15d21a89f13"

# $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"


$refreshToken ='0.Axxxxxx'


# Define your tenant ID, client ID, and refresh token
# $tenantId = "your-tenant-id"  # Replace with your actual tenant ID
# $clientId = "your-client-id"  # Replace with your actual client ID
$refreshToken = $refreshToken # Replace with your actual refresh token
# If your application is a confidential client, uncomment the next line and specify your client secret
#$clientSecret = "your-client-secret"  # Replace with your actual client secret if needed

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
    Write-Host "New Refresh Token: $($response.refresh_token)"
}