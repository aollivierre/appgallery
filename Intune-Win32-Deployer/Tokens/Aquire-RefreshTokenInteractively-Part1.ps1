$clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
# $clientSecret = "CFu8Q~ITd-NIsZCy3ZQgjoF-cqvmhQqwc~9ZGcPX"
# $tenantName = "bellwoodscentres.onmicrosoft.com"
$tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

# Define variables
# $tenantId = "<Your-Tenant-ID>"
# $clientId = "<Your-Client-ID>"
# $redirectUri = "http://localhost:8080/"


$scope = "openid%20offline_access%20User.Read%20Mail.Read" # Include 'offline_access' for refresh token
$authUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope&response_mode=query"

# Start a listener on port 8080
Start-Process "powershell" -ArgumentList "-Command `"`$Listener = [System.Net.HttpListener]::new(); `$Listener.Prefixes.Add('http://+:8080/'); `$Listener.Start(); Write-Host 'Listening...'; `$Context = `$Listener.GetContext(); `$Response = `$Context.Response; `$Response.OutputStream.Write([Text.Encoding]::UTF8.GetBytes('You can close this window now'), 0, 36); `$Response.Close(); `$Listener.Stop(); Write-Host 'Code: ' + `$Context.Request.QueryString['code'];`""

# Open the authorization URL in the default web browser
Start-Process "chrome.exe" $authUrl # Use 'chrome.exe' or another browser if preferred