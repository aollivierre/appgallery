$clientId = '3c9b3719-36a9-47d3-881e-8321d6823592'
$clientSecret = 'StI8Q~3Q~tRT.m3Zyni6C7Ea_yW5MX5nmM~yKctO'
$tenantName = 'cna365.onmicrosoft.com'
# $site_objectid = '7f764990-e69d-41fc-b62c-d833b16bb8ab'
$webhook_url = 'https://cna365.webhook.office.com/webhookb2/7f764990-e69d-41fc-b62c-d833b16bb8ab@8bb6061d-2d46-4095-9f9e-41cfcbc1e9f1/IncomingWebhook/1ed31e5d1da34bb99e0673029ddd26f6/2d6b0104-7a5d-45c9-a73b-4d7e3b500327'


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