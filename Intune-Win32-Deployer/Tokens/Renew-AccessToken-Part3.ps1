$clientId = "b075578c-6300-4bae-8458-84e936411eb7"
# $clientSecret = "CFu8Q~ITd-NIsZCy3ZQgjoF-cqvmhQqwc~9ZGcPX"
# $tenantName = "bellwoodscentres.onmicrosoft.com"
$tenantID = "bfe58736-eeb3-4527-b77c-c15d21a89f13"

# $RedirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"


$refreshToken ='0.AXgANoflv7PuJ0W3fMFdIaifE4xXdbAAY65LhFiE6TZBHrd4AE4.AgABAAEAAAAmoFfGtYxvRrNriQdPKIZ-AgDs_wUA9P-jjWb2V5mw0q6gKTdKyJnHj01TpCT5hoBzrwByn5uzY0ZqZ3raWspEMdNWQlrRsa2FmmvEInguXeDfkEyAGK0aKKMAzIO-2uBcqFIZ17PjdynFIoECT1QmjekaypUKTk-WMQ3vMqK5cxyKSSs5v0f_fOXgsevP8xIGQVTmD0W7pO1f3DQB-J7gYhs4EwfXScR0cuqDTxrYvwUMKmHmRNh7R66N-W3JwxQJEmSG4zEMt1qa4wzoub9gr1ZAa6UZWTkpql_pfKp5VdOd1-p7FhlTfu-3pgCZ66JpWpZQZUhFhxdUq24cedwC3gAa8YHQLNrMxNu-5HiYVhyzIBw4Gcni1zho45Hh0clkSGisixsVV9mrIZvU5IKOw-Pwg-Uwu0Ov7yYulvrffIOfYltGKMLZcosS-XghmdalZqMPe04qzrkYZw__3QJjGPrrrh4Mv4wpoAMWyKPjcg71ocLjbBHGvjYJNe2ACPWjZxI0thqok8Bgkeo4xiORZSJHbDlfRx5kC3ayzYQB3Ky7mUA4mlW_AX0cgrZVaWuPlwh3eVWe-t4gk0ud5d8IBQmPk8HK7_jyOQ8egEP4xk-EmrRs0wL-ouusVu4oUVnMe6KT67ExubskjeEhayGFvuOO44QjU_eZ3oJT3FnNYHkAKV6a-y4ZO0IQPAqK_1_8DfbRc21dq11jzzoLdUjiZ9TOKVjNjJWgdXT_AM7At0wN9t2Aje11nwLiUXrm6H1J3nPodk3iXav99rycehAYcPP9YCg7pfARqgX0k0-1ul1XxeqhIda1roa4bs7yiSaaVvSeLLoiHelfQcwdNjeNQfD4EcrMFsY7vzmOalDOS4RTPt7fKodcNaNXMWYGXPY'


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