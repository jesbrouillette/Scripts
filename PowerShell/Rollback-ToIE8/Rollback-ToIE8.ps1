#-----------------------------
#VARS
#-----------------------------
#aws creds
$awsAccessKey = $env:AWS_ACCESS_KEY_ID
$awsSecretKey = $env:AWS_SECRET_KEY

$awsBucket = $env:RDS_CONFIG_SOURCE_BUCKET
$awsFolderPath = $env:RDS_CONFIG_FOLDER_PATH
$appName = $env:RDS_CONFIG_REMOVE_IE9

$srcFileName = "MicrosoftFixit50778.msi"

#-----------------------------

#-----------------------------
#MAIN
#-----------------------------

$error.clear()

$remove_hotfixes = @("2841134","2718695","2817183")

$installed_hotfixes = Get-Hotfix | Select -Expand HotfixID

foreach ($hotfix in $remove_hotfixes) {
	$kb = "KB{0}" -f $hotfix
	if (($installed_hotfixes -contains $kb) -or ($installed_hotfixes -contains $hotfix)) {
		Write-Host "REMOVE_HOTFIX:  Found Hotfix $hotfix."
		$wusa = Start-Process wusa -ArgumentList "/uninstall /kb:$hotfix /quiet /norestart" -Wait
		if (!$Error) { Write-Host "REMOVE_HOTFIX:  Hotfix $hotfix has been removed." ; $reboot = $true }
		else { Write-Host "REMOVE_HOTFIX:  Hotfix $hotfix was not removed." }
	}
}

switch ($reboot) {
	$true { rs_shutdown -r -i ; start-sleep 300 }
	$false { Write-Host "REMOVE_HOTFIX:  No hotfixes found that need to be removed." }
	default { Write-Host "REMOVE_HOTFIX:  No hotfixes found that need to be removed." }
}

$ieVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Program Files (x86)\Internet Explorer\iexplore.exe").FileVersion

if ($ieVersion -ge 9) {

	Set-AWSCredentials -AccessKey $awsAccessKey -SecretKey $awsSecretKey

	write-Host "RDSCONFIG`:  Starting - $appName"
	write-host "RDSCONFIG`:  $appInstFile"

	$downLoadDir = "c:\RSDownloads"
	$instLogDir = "c:\RSDownloads\Logs"

	$downloadPath = $downLoadDir + "\" + $awsFolderPath.replace("/","\") + "\" + $appName

	write-host "DOWNLOAD`:  Destination Directory - $downloadPath"
	if(!(test-path $downloadPath)){new-item $downloadPath -itemtype Directory -force}
	if(!(test-path $instLogDir)){new-item $instLogDir -itemtype Directory -force}

	#download all source files
	$srcFolderPath = $awsBucket + "/" + $awsFolderPath + "/" + $appName

	write-host "DOWNLOAD`:  Download Bucket - $awsBucket"
	write-host "DOWNLOAD`:  Folder Path - $awsFolderPath"
	write-host "DOWNLOAD`:  Destination - $downloadPath"

	$awsKeyPrefix = $awsFolderPath + "/" + $appName
	write-host "DOWNLOAD`:  KeyPrefix - $awsKeyPrefix"

	write-host "DOWNLOAD`:  Starting download"
	write-host "DOWNLOAD1:  CMD - read-S3Object -BucketName $awsBucket -KeyPrefix $awsKeyPrefix -Folder $downloadPath"
	read-S3Object -BucketName $awsBucket -KeyPrefix $awsKeyPrefix -Folder $downloadPath

	write-host "DOWNLOAD`: Finished Download"
	write-host "DOWNLOAD`: Starting IE9 removal"

	$fullPath = "{0}\{1}" -f $downloadPath,$srcFileName

	$process = Start-Process msiexec.exe -ArgumentList @("/i",$fullPath,"/qn","/norestart") -Wait -PassThru

	if ($process.ExitCode -eq 0) {
		Write-Host "IE9:  Removal completed.  Rebooting"
		rs_shutdown -s -i
	}
	else {
		Write-Host "IE9:  Removal failed."
	}
}