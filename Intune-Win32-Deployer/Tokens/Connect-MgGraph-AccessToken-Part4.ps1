$clientId = "cc9a5e95-f33d-45f9-a942-4eb1d0b50e92"
$tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

$refreshToken ='0.AXgANoflv7PuJ0W3fMFdIaifE5Vemsw98_lFqUJOsdC1DpJ4AOA.AgABAAEAAAAmoFfGtYxvRrNriQdPKIZ-AgDs_wUA9P8JHLDLZbvx6evTZBj7o-7EwVbBG6pZXK4DLt0BFQUAi0sz-rWUme11jZj4tArzuWPwupsq3UXQOL7j_DEJFO28RaDRwYylFdBbmLRjoP0NW0EBUpk-_1E4yqlz7b5yT5XwVSOLvL2dBv19EZJzGzAn76KX6wTNbUCqWhjrs04J6VJrmBK1bUzjL2PdOtkddPxXFt7ZcTF4AEyDXXNuO8_ZCRmrkMcMgjCjsqYV5RSti6KNWur4H-1-eiOZXqwekzA-a1SGxcCEqRyggiFvtEXME5sXmQDCK2HfukJNwxrI6E_mu6g5xTH4lfM1UQz7Lly2m3Opclo-KQn_YGFLTRvOa1yqyzCzttZYYCBmaVm9IMleLjoVphJpEjXXwXrdbfmcBG37U4gWw6vAW7NO6TEdnRqzfpviSaa2IKYjuNXnK52N6HlB5B4c0ZEaNDsa2UDtNG64hwGZnR8yHMS9ZlaBttfrn3kXuoLd8l6T1ICVjEvH_vbHMthMJGsKzET1bMqkAo6pvtTK3Cwn2aO4CCePgnfgbbbrWzYx9t070arE_XgUfezok3EYMbMN51YBBjIc6kuZTp9_EtI4dqWiGLjsN8QEpRpzOxP3__fSM0JI27jcEYjrD5ZJmFEjwHsddTzUr5j9EZqJeUCfrUkKYb1jvYVjOvzAD9oWdFkwPsENI0DGcGdCcgUS22GgvZc6AF_XF_qb7OQ6e-hCDm7tb6yND0wmTMq4r2t1Zpp2NvTeZwfWK1cYLElVLkgL_x2BoifA6ZoioiIADGZAwrWYRQ'


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