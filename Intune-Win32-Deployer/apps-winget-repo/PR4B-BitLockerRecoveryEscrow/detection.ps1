
$clientId = "b075578c-6300-4bae-8458-84e936411eb7"
# $tenantName = "bellwoodscentres.onmicrosoft.com"
$tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

# $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

$refreshToken ='0.AXgANoflv7PuJ0W3fMFdIaifE4xXdbAAY65LhFiE6TZBHrd4AE4.AgABAAEAAAAmoFfGtYxvRrNriQdPKIZ-AgDs_wUA9P_Bi525T2k3JAlxzaCgcJOpr7sVYraNzCGEI5h__Kv-9wZ7hWsM-1FLjl5s9tZrTHFTFBjROT0Bcpi9qSHZaCcArSrkbbLiPUIFo5v9wO1HYmJMjhOH6kmfusaz_ThMqAKkVvgT2nyWcHsMYRAJXb_1oy7abBHuSGmaaecGjdxjg6e1S4H-e5kqWgta8vCDFZ9EMXuTRVF3Luw5MhmJEqA-XtNJ4sgm1fPCf1zyY8mujfc2YFloVy23PLogZ6BX91heO5sUrnnm09n7GrF4bjo01aMUlS9fd9xK9n6C49N5KC1FYlwqK8MfmiySwNCsDJRpkExzuvlvzjkzX_3N5dNaCIKs5l2TSATCi4M2qijg-kW66L2eMsyO_GKyHxdIbzUdSksXh6-v_qNvQ7fFoBZEiKxac3duZEtQu5DJU414FXLqYcUe_APlDT6NDLy1SDn6tw4xpZc8BsYB97nqXB66C67xX7sZxmpCvgs-Ph4GV-7nrUz3UUCJ3qEUZ5y3XBSapxZiPBC9i72JWEXgV3uXYwz9JafhoWkoICF0iSA7Fj9ulpALxmXblLCFHNwX_skqgE7EHq3EHUGtcTZI0h1QraPe_9wrOak1WPXLYXR4qwdTnlK6ODMT5LNCmmDJ113uB4ns4ysknW4ja_EVv6OKqpsjKLH1YDRfzDFvTXK0kt3nLjg5FsxsgS71KA0H1-pb1rCuVFAlZwXVvLqZ8e4eRN24T7DQdfCWDoImMCRzzqYaADih7i7tdy8eZO5r1mi-WvcYwAjgEb5gASfl2DOJWxHGj0OZyc8xMMHlMXppc4du8-ld7Ltn7go4v1bthfcxKsXcdAMTTq905YH60H16iIH8xJQFdH8'


# Token endpoint
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Prepare the request body. Exclude 'client_secret' if your app is a public client.
$body = @{
    client_id     = $clientId
    grant_type    = "refresh_token"
    refresh_token = $refreshToken
    # Uncomment the next line if your application is a confidential client
    scope         = "https://graph.microsoft.com/.default"  # Adjust this scope according to your needs
}

# Make the POST request
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

# Output the new access token and refresh token
# Write-Host "New Access Token: $($response.access_token)" #uncomment for debugging
# Some authorization servers might not return a new refresh token every time you refresh an access token
if ($response.refresh_token) {
    # Write-Host "New Refresh Token: $($response.refresh_token)" #uncomment for debugging
}



$AccessToken= $response.access_token

# Assuming your access token is stored in a variable named $accessTokenString

# Convert the plain string token to a SecureString
# $AccessToken = $accessTokenString | ConvertTo-SecureString -AsPlainText -Force


# Set up headers for API requests
$headers = @{
    "Authorization" = "Bearer $($accessToken)"
    "Content-Type"  = "application/json"
}


# Run dsregcmd /status and capture the output
$dsregcmdOutput = & dsregcmd /status

# Convert the output to a string to ensure consistent handling
$dsregcmdOutputString = $dsregcmdOutput -join "`n"

# Use a regular expression to find the DeviceId more reliably
if ($dsregcmdOutputString -match "DeviceId\s*:\s*([-\w]+)") {
    $DeviceId = $matches[1]
} else {
    # Write-Host "Device ID not found. Ensure the device is Azure AD joined."
    # exit 1
}

if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    # Write-Host "Device ID: $DeviceId"

    # Continue with your script...
} else {
    # Write-Host "Device ID not found. Ensure the device is Azure AD joined."
    # exit 1
}


if (-not $DeviceId) {
    # Write-Host "Device ID not found. Ensure the device is Azure AD joined."
    # exit 1
} else {
    # Write-Host "Device ID: $DeviceId"

    # Ensure DeviceId is set
    # $DeviceId = '6d298358-fa28-438c-9139-e4b75ccac34c'

    # Construct the Graph API URI with the filter query
    $FilterQuery = "`$filter=deviceId eq '$DeviceId'"
    $GraphUri = "https://graph.microsoft.com/v1.0/informationProtection/bitlocker/recoveryKeys?$FilterQuery"

    # Display the constructed URI for debugging
    # Write-Host "Constructed URI: $GraphUri"

    $Headers = @{
        Authorization = "Bearer $AccessToken"
    }

    try {
        $BitlockerKeysResponse = Invoke-RestMethod -Uri $GraphUri -Headers $Headers -Method Get

        if ($null -ne $BitlockerKeysResponse.value -and $BitlockerKeysResponse.value.Count -gt 0) {
            # Write-Host "Filtered Bitlocker key(s) found escrowed in Azure AD for Device ID: $DeviceId"
            foreach ($key in $BitlockerKeysResponse.value) {
                # Write-Host "Key ID: $($key.id) - Created: $($key.createdDateTime) - Volume Type: $($key.volumeType) - Device ID: $($key.deviceId)" 
                #No remediation needed
            }
            exit 0 
        } else {
            # Write-Host "No Bitlocker keys found escrowed in Azure AD for Device ID: $DeviceId" 
            #Remediation needed
            exit 1 
        }
    } catch {
        # Write-Error "Failed to query Bitlocker keys from Azure AD: $_"
        exit 2
    }
}