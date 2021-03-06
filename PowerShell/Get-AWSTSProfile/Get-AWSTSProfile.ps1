#-----------------------------
#VARS
#-----------------------------
#aws creds
$awsAccessKey		= $env:AWS_ACCESS_KEY_ID
$awsSecretKey		= $env:AWS_SECRET_KEY
$awsBucket			= $env:RDS_CONFIG_SOURCE_BUCKET
$awsFolderPath		= $env:RDS_CONFIG_FOLDER_PATH
$awsSourceFolder	= $ENV:RDS_CONFIG_SOURCE_FOLDER
$tsProfilePath		= $ENV:RDS_CONFIG_TS_PROFILE_PATH
#-----------------------------

#-----------------------------
#MAIN
#-----------------------------

Set-AWSCredentials -AccessKey $awsAccessKey -SecretKey $awsSecretKey

write-host "DOWNLOAD`:  Destination Directory - $tsProfilePath"
if(!(test-path $tsProfilePath)){new-item $tsProfilePath -itemtype Directory -force}

#download all source files
$srcFolderPath = $awsBucket + "/" + $awsFolderPath + "/" + $awsSourceFolder

write-host "DOWNLOAD`:  Download Bucket - $awsBucket"
write-host "DOWNLOAD`:  Folder Path - $awsFolderPath"
write-host "DOWNLOAD`:  Destination - $downloadPath"

$awsKeyPrefix = $awsFolderPath + "/" + $awsSourceFolder

read-S3Object -BucketName $awsBucket -KeyPrefix $awsKeyPrefix -Folder $tsProfilePath

write-host "DOWNLOAD`: Finished Download"

write-host "Finished installing / configuring $tsProfilePath"