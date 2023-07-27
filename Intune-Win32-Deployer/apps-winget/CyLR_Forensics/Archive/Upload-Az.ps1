# Install-Module -Name Az -AllowClobber -Scope CurrentUser

$azureAppId = "3c9b3719-36a9-47d3-881e-8321d6823592"
$azureTenantId = "8bb6061d-2d46-4095-9f9e-41cfcbc1e9f1"
$azurePassword = ConvertTo-SecureString "Ied8Q~SaDAA-.7csdNV0P35qB78NelrJFJ7Erds2" -AsPlainText -Force
$azureCredential = New-Object System.Management.Automation.PSCredential($azureAppId, $azurePassword)

Connect-AzAccount -ServicePrincipal -Credential $azureCredential -Tenant $azureTenantId



# Install-Module -Name Az -AllowClobber -Scope AllUsers
# Connect-AzAccount
# $resourceGroupName = "YourResourceGroupName"
$resourceGroupName = "cylr2"
# $location = "YourAzureLocation"
$location = "West US 3"
# $storageAccountName = "YourStorageAccountName"
$storageAccountName = "cylrsa002"

# New-AzResourceGroup -Name $resourceGroupName -Location $location
# New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2
# $containerName = "YourContainerName"
$containerName = "cylcontainer002"
$storageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName).Value[0]
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

# New-AzStorageContainer -Name $containerName -Context $storageContext
# $localFilePath = "C:\path\to\your\cylr_archive.zip"
$localFilePath = "C:\Intune\Win32\cylr\cylr_archive.zip"
$blobName = "cylr_archive2.zip"

# Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext -Type Block


Set-AzStorageBlobContent -File $localFilePath -Container $containerName -Blob $blobName -Context $storageContext

