$clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
# $clientSecret = "CFu8Q~ITd-NIsZCy3ZQgjoF-cqvmhQqwc~9ZGcPX"
# $tenantName = "bellwoodscentres.onmicrosoft.com"
$tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

$RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

# Assume $url contains the full redirect URL
$url = "https://login.microsoftonline.com/common/oauth2/nativeclient?code=0.AXgANoflv7PuJ0W3fMFdIaifE5Vemsw98_lFqUJOsdC1DpK2AHM.AgABAAIAAAAmoFfGtYxvRrNriQdPKIZ-AgDs_wUA9P8GPYivft-Lm0KKZA1YX4X800LKyFEc-f1ox5oTpM2V5dde95DR21v3kic76GKSB1_CVzkHcPpS__y0X98vPGOeGWos8jmP9KhE3cY2VM7GyGr3sBCJ6Qhi3GmTA-l9LU3La6MScbu2oR5bJbUWRhGh9sf1Zf5C9tsrlmc8FqcUg3LiBgrHAmWWmm9bv6n6-DsS3YR15ScTHyQHiNVadQo-qgU65pKVuowFF2wsi2guQMGynU-oVUMFUnewLznSxuIxPs-QpaLD9ij_45PA8IpKQGTbOWQ6s_n9pcp2jp6S152DXBlqiXrFs9BGYHnGhVu2RTrrRzF8xc7acHgGKqgoSlbatyM7W0rvl271wO87bLT0hqNxl4JghuvZGvPsSd0gGO7Hx1ag8yHIjSD_cTjOomivUS6IcegiJBHnyr8tziG2a1CiE3NwpgVXoLuJNoOx91Ilbcsclocfm1Wn-NHtP6c8Cw4bYo8T55VORl0xtBsTlAv5U4bXKBUYguUaNEMXXljU1PFiU4SsTpV1_PY5ISxWLt-pnydGrycjZjxykEzqqoA9qFj9fpTVVsEgohTG3W2MqDy06ZEzPCpUZg_XGsgpZBf6K0hIZec1wXNU68agTwbQNX3NDCJElbt6N70drRjywj_l5Jy_Cq_797kgDYMlVGuXPVAHL56S0tXIt6S3_Ntvz9s26BYR_o89lo3u-E7xse7o6PtBUPrNxj7Dky2SoGB05cM5V49DWFtJPqCrcKOxfTMg3z5F54KvlQuI1hH0EkjFeE36aA&session_state=bc91b3fa-8af0-4c76-aae2-6d882009f30a"

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