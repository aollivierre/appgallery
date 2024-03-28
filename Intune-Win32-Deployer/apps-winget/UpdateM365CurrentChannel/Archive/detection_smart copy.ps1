# Client credentials
$tenantId = "<Your-Tenant-ID>"
$clientId = "<Your-Client-ID>"
$clientSecret = "<Your-Client-Secret>"
$resource = "https://graph.microsoft.com"
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Fetch the OAuth token
$tokenBody = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody
$token = $response.access_token

# Query the Microsoft Graph API for Office version (This is a placeholder, as the exact endpoint might differ)
$headers = @{
    "Authorization" = "Bearer $token"
}
$officeVersionInfo = Invoke-RestMethod -Uri "$resource/v1.0/<relevant-endpoint>" -Headers $headers

# Extract and display the version info
$latestVersion = $officeVersionInfo.<relevant-property>
Write-Output "The latest version of Microsoft Office is: $latestVersion"
