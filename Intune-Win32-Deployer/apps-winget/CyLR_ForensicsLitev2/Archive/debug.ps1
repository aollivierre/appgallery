$clientId = 'xxxxxxxxxx-8321d6823592'
$clientSecret = 'xxxxxxxxxxxxxxxxxxx'
$tenantName = 'contoso.onmicrosoft.com'
# $site_objectid = '7f764990-e69d-41fc-b62c-d833b16bb8ab'
$webhook_url = 'https://contoso.webhook.office.com/webhookb2/xxxxxxxxxxxxxx'


function Get-MicrosoftGraphAccessToken {
    $tokenBody = @{
        Grant_Type    = 'client_credentials'  
        Scope         = 'https://graph.microsoft.com/.default'  
        Client_Id     = $clientId  
        Client_Secret = $clientSecret
    }  

    $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $tokenBody -ErrorAction Stop

    return $tokenResponse.access_token
}








$site_objectid = $null
function Get-M365GroupObjectId {
    param (
        [Parameter(Mandatory=$true)]
        [string]$groupEmail
    )

    $url = "https://graph.microsoft.com/v1.0/groups"
    $groups = @()

    do {
        $response = Invoke-RestMethod -Headers $headers -Uri $url -Method Get
        $groups += $response.value
        $url = $response.'@odata.nextLink'
    } while ($url)


    # #DBG

    $group = $groups | Where-Object { $_.mail -eq $groupEmail }

    if ($group) {
        return $group.id
    } else {
        # Write-EnhancedLog -Message "M365 Group not found with email address: $groupEmail" -Level "DEBUG" -ForegroundColor ([ConsoleColor]::Yellow)
        return $null
    }
}








   $accessToken = Get-MicrosoftGraphAccessToken
    
    # Set up headers for API requests
    $headers = @{
        "Authorization" = "Bearer $($accessToken)"
        "Content-Type"  = "application/json"
    }


    # $site_objectid = Get-M365GroupObjectId -groupDisplayName "Syslog"

    $site_objectid = Get-M365GroupObjectId -groupEmail "SysLog@cna-aiic.ca"


    $site_objectid



    $DBG