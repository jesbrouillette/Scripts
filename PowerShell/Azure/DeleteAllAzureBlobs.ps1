
cls

Import-Module 'C:\Program Files (x86)\Microsoft SDKs\Windows Azure\PowerShell\Azure\azure.psd1'
Import-AzurePublishSettingsFile 'xxxxx'

$blobsOut = @()
$deleteBlob = $true

$azStorageAccounts = Get-AzureStorageAccount

foreach($azSA in $azStorageAccounts)
{
  Write-Host $azSA.storageaccountname  
  $saName = $azSA.storageaccountname
  $saKey = (Get-AzureStorageKey -StorageAccountName $saName).primary
  
  $context = new-AzureStorageContext -StorageAccountName $azSA.StorageAccountName -StorageAccountKey $saKey
  
  $cred = New-Object 'Microsoft.WindowsAzure.Storage.Auth.StorageCredentials' $saName, $saKey
  $client = New-Object 'Microsoft.WindowsAzure.Storage.Blob.CloudBlobClient' "https://$saName.blob.core.windows.net", $cred

  #get containers
  $saConts = Get-AzureStorageContainer -Context $context
  
  foreach($saCont in $saConts)
  {
    $contName = $saCont.name
	$azCont = $client.GetContainerReference($contName)

    $allBlobs = $azcont.ListBlobs()
	
	foreach($blob in $allBlobs)
	{
      Write-Host "Found Blob`: $($blob.name)"
	  Write-Host "Getting Blob Info"
	  
	  $blobInfo = "" | select Name,StorageAccount,Container,Type,LeaseStatus,LeaseState,LeaseDuration,LastModified	  
	  $blobProps = $blob.Properties
	  
	  $blobInfo.Name = $blob.Name
	  $blobInfo.StorageAccount = $saName
	  $blobInfo.Container = $contName
	  $blobInfo.Type = $blobProps.BlobType
	  $blobInfo.LeaseStatus = $blobProps.LeaseStatus
	  $blobInfo.LeaseState = $blobProps.LeaseState
	  $blobInfo.LeaseDuration = $blobProps.LeaseDuration
	  $blobInfo.LastModified = $blobProps.LastModified
	  
	  $blobsOut += $blobInfo
	  
	  if($deleteBlob)
	  {
	    Write-Host "Breaking Blob Lease"
	    $blob.BreakLease()
	  
	    Write-Host "Deleting Blob"
	    $blob.Delete()
	  }
	}
  }
  
  

}