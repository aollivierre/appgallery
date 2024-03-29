$clientId = "xxxxxxx-4eb1d0b50e92"
# $clientSecret = ""
# $tenantName = "contoso.onmicrosoft.com"
$tenantID = "xxxxxx-c15d21a89f13"

$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

# Assume $url contains the full redirect URL
$url = "https://login.microsoftonline.com/common/oauth2/nativeclient?code=0.Axxxxxxxxxxxxxxx"

# Extract the code from the URL
$code = $url -split "code=" | Select-Object -Last 1
$code = $code -split "&" | Select-Object -First 1

# Output the code
Write-Host "Authorization Code: $code"





# Authorization code obtained from listener output
# $code = "<Authorization-Code-From-Listener>"

# Define the tenant and client IDs
# $tenantId = "<Your-Tenant-ID>"
# $clientId = "<Your-Client-ID>"

# Define the token URL
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Prepare the body for the POST request
$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"  # Adjust the scope as necessary
    code          = $code
    redirect_uri  = $RedirectUri  # Ensure this matches the redirect URI registered in Azure AD
    grant_type    = "authorization_code"
    # Do not include the client_secret for a public client
}

# Make the POST request
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Output the access and refresh tokens
Write-Host "Access Token: $($response.access_token)"
Write-Host "Refresh Token: $($response.refresh_token)"