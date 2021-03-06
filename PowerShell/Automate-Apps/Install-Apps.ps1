param (
	[string]$bucket			= "https://s3.amazonaws.com/JesB-East",		#S3 Bucket with install & config files
	[string]$manifest		= "manifest.xml",							#XML file with install & config content
	[string]$tempFolder		= "C:\Temp\Install-Apps",					#Temp location to dowload files into
	[string]$logFile		= "C:\RSTools\Logs\Automate-AppKits.log",	#Log folder location for this script
	[string]$regKey			= "HKLM:\SOFTWARE\RightScale",				#Registry Key used for default run values
	
	[string]$rs_instance_id				= $INSTANCE_ID,					#RightScale Instance ID 														: Default & Hidden in RightScript
	[string]$PRIVATE_IP					= $PRIVATE_IP,					#RightScale Private IP 															: Default & Hidden in RightScript
	[string]$PUBLIC_IP					= $PUBLIC_IP,					#RightScale Public IP 															: Default & Hidden in RightScript
	[string]$DATACENTER					= $DATACENTER,					#RightScale Datacenter in which the server is running (EC2 availability zone) 	: Default & Hidden in RightScript
	[string]$RS_EIP						= $RS_EIP,						#RightScale Elastic IP address as issued by Amazon EC2 							: Default & Hidden in RightScript
	[string]$RS_SERVER					= $RS_SERVER,					#RightScale server name in my.rightscale.com 									: Default & Hidden in RightScript
	[string]$RS_SKETCHY					= $RS_SKETCHY,					#RightScale Sketchy server 														: Default & Hidden in RightScript
	[string]$RS_TOKEN					= $RS_TOKEN,					#RightScale Token as 32 character alphanumeric string 							: Default & Hidden in RightScript
	[string]$RS_SERVER_NAME				= $RS_SERVER_NAME,				#RightScale Server Name as displayed in the dashboard 							: Default & Hidden in RightScript
	[string]$RS_DEPLOYMENT_NAME			= $RS_DEPLOYMENT_NAME,			#RightScale Deployment Name as displayed in the dashboard 						: Default & Hidden in RightScript
	[string]$RS_SERVER_TEMPLATE_NAME	= $RS_SERVER_TEMPLATE_NAME,		#RightScale Template Name as displayed in the dashboard 						: Default & Hidden in RightScript
	[string]$RS_INSTANCE_UUID			= $RS_INSTANCE_UUID				#RightScale Universally-unique identifier for this server incarnation 			: Default & Hidden in RightScript
)

# BEGIN FUNCTIONS

function ValidateRun {
	function CreateString {
		param (
			[string]$toolName,
			[string]$regKeyValue,
			[string]$runIndicator,
			[string]$runValue,
			[string]$executeStatus
		}
			
		"Registry key $toolName is set to $regKeyValue indicating it has $runIndicator been run.  $toolName is set to $runValue and will now be $executeStatus."
	}
	param (
		[string]$toolName,
		[string]$runValue
	)
	$regKeyValue = (Get-ItemProperty $regKey).$toolName
	
	if (!$regKeyValue) { return $true }
	
	switch ($runValue) {
		0 {$runIndicator = "not"}
		1 {$runIndicator = "already"}
	}
	
	switch ($runValue) {
		"runonce"	{	if ((Get-ItemProperty $regKey).$toolName -eq "1") {
							WriteLog (CreateString $toolName $regKeyValue $runIndicator $runValue "skipped")
							return $false
						}
						else {
							WriteLog (CreateString $toolName $regKeyValue $runIndicator $runValue "run")
							return $true
						}
					}
		"always"	{	WriteLog (CreateString $toolName $regKeyValue $runIndicator $runValue "run")
						return $true
					}
							
		default		{	WriteLog "$toolName RUNVALUE is not set to a valid value.  Excution is being skipped."
						return $false
					}
	}
							
}

function CheckReg {
	param (
		[string]$regPath,
		[string]$regKey
	)
	(Get-ItemProperty $regPath).$regKey
}

function WriteLog {
	param (
		$text
	)
	$logText = "{0}: {1}" -f $(&$dateBlock),$text
	
	Write-Host $logText
	Write-Output $logText | Add-Content $logFile -Force
}

function UpdateRegistry {
	param (
		$path,
		$keyname,
		$keytype,
		$value,
		$name
	)

	WriteLog "Starting registry action - $name"
	WriteLog "Registry Key path - $path"
	WriteLog "Registry Key name - $keyname"
	WriteLog "Registry Key type - $keytype"
	WriteLog "Registry Key value - $value"
	WriteLog "Setting registry $path,$name=$value"
	
	try { Set-ItemProperty -Path $path -Name $keyname -Value $value -Type $keytype }
	catch { WriteLog "Error setting registry $path - $_" }
	finally { WriteLog "Finished registry action - $name" }
}

function CreateDirectory {
	param (
		[string]$path,
		[string]$name
	)
	if (!(Test-Path $path)) {

		WriteLog "Starting directory creation action - $name"
		WriteLog "Directory - $path"
		
		try { New-Item $path -ItemType Directory -ErrorAction Stop | Out-Null }
		catch { WriteLog "Error creating $path - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
		finally { WriteLog "Finished directory action - $path" }

		Start-Sleep -Milliseconds 500
	}
}

function DownloadFile {
	param (
		[string]$source,
		[string]$destination,
		[string]$name
	)
	
	WriteLog "Starting download action - $name"
	WriteLog "Source - $source"
	WriteLog "Destination - $destination"

	$file = $source.Split("/")[-1]
	
	if ($destination.Length-1 -ne "\") { $destination = $destination + "\" + $file }
	else { $destination = $destination + $file }
	
	try {
		$wc.downloadfile($source,$destination)
	}
	catch [System.Net.WebException] {
		if($_.Exception.InnerException) { WriteLog "Error downloading $source to $destination - $($_.exception.innerexception.message)" }
		else { WriteLog "Error downloading $source - $_" }
	}
	catch {
		 WriteLog "Error downloading $source to $destination - $_"
	}
	finally {
		 WriteLog "Finished downloaded action - $name"
	}
}

function CopyFile {
	param (
		[string]$source,
		[string]$destination,
		[string]$name
	)
	
	WriteLog "Starting copy action - $name"
	WriteLog "Source - $source"
	WriteLog "Destination -  $destination"
	
	try { Copy-Item -path $source -Destination $destination -Force }
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished file copy action - $name" }
}

function InstallApp {
	param (
		[string]$cmd,
		[string]$cmdArgs,
		[string]$name
	)
	WriteLog "Starting installation action - $name"
	WriteLog "Installer - $cmd"
	WriteLog "Arguements - $cmdArgs"

	try { Start-Process $cmd -ArgumentList $cmdArgs -Wait }
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished installation action - $name" }
}

function ManipulateService {
	param (
		[string]$service,
		[string]$command,
		[string]$name
	)
	WriteLog "Manipulate service action - $name"
	WriteLog "Service - $service"
	WriteLog "Command - $command"

	switch($command) {
		"stop" {
			try { Stop-Service -Name $service -Force - }
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished stoping service action - $name" }
		}
		"start" {
			try { Start-Service -Name $service }
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished starting service action - $name" }
		}
		"restart" {
			try { Restart-Service -Name $service }
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished restarting service action - $name" }
		}
	}
}

function StartCommandline {
	param (
		[string]$path,
		[string]$file,
		[string]$cmdArgs,
		[string]$name,
		[string]$wrkFolder
	)

	WriteLog "Running command line action - $name"
	WriteLog "Path - $path"
	WriteLog "File - $file"
	WriteLog "Arguements - $cmdArgs"
	WriteLog "Working folder - $wrkFolder"

	$filePath = "{0}\{1}" -f $path, $file

	try { Start-Process -FilePath $filePath -ArgumentList $cmdArgs -WorkingDirectory -ErrorAction "Stop" }
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished restarting service action - $name" }
	
}

function ReplaceText {
	param (
		[string]$file,
		[string]$find,
		[string]$replace,
		[string]$name
	)

	WriteLog "Running find and replace action - $name"
	WriteLog "File - $file"
	WriteLog "Find - $find"
	WriteLog "Replace - $replace"

	try { (gc $file).Replace($find,$replace) }
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished find and replace action - $name" }
}

function InsertText {
	param (
		[string]$file,
		[string]$text,
		[string]$line,
		[string]$name
	)

	WriteLog "Running insert text action - $name"
	WriteLog "File - $file"
	WriteLog "Text - $text"
	WriteLog "Line - $line"

	$srcContent = gc $file
	$content = $srcContent[0..($line-1)] + $text + $srcContent[$line..($srcContent.Length)]
	
	try { $content | Set-Content $file -Force }
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished insert text action - $name" }
}

function ExecuteScriptBlock {
	param (
		[string]$block,
		[string]$name
	)

	WriteLog "Running scriptblock action - $name"
	WriteLog "Scriptblock - $($block.ToString())"

	try { &$executioncontext.invokecommand.NewScriptBlock($block) }
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished scriptblock action - $name" }
}

function Uncompress {
	param (
		[string]$source,
		[string]$destination,
		[string]$name
	)

	WriteLog "Starting uncompress action - $name"
	WriteLog "Compressed file - $source"
	WriteLog "Destination path - $destination"
	
	try {
		if (!(Test-Path -path $destination)) { New-Item $destination -Type Directory }
		zip x -y "-o$$destination" $source
	}
	catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
	finally { WriteLog "Finished scriptblock action - $name" }
}

function ModifyEnvVar {
	param (
	 	[string]$envvar,
		[string]$type,
		[string]$action,
		[string]$value,
		[string]$name
	)

	WriteLog "Starting environment variable action - $name"
	WriteLog "Variable being modified - $source"
	WriteLog "Variable type - $type"
	WriteLog "Variable action - $action"
	WriteLog "Value being set - $value"
	WriteLog "Current Value - $([Environment]::GetEnvironmentVariable($envvar,$type))"

	switch($action) {
		"add" {
			try {
				$item = [Environment]::GetEnvironmentVariable($envvar,$type)
				if (($item.Replace("`"", "").Split(";") | Sort-Object -unique) -notcontains $value) {
					$set = [Environment]::SetEnvironmentVariable($envvar,[Environment]::GetEnvironmentVariable($envvar,$type) + ";$($value)",$type)
				}
				else { WriteLog "$envvar already contains $value" }
			}
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished scriptblock action - $name" }
		}
		"remove" {
			try {
				$item = [Environment]::GetEnvironmentVariable($envvar,$type)
				if (($item.Replace("`"", "").Split(";") | Sort-Object -unique) -contains $value) {
					$set = [Environment]::SetEnvironmentVariable($envvar,$item.Replace($value,""),$type)
				}
				else { WriteLog "$envvar does not contain $value" }
			}
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished scriptblock action - $name" }
		}
		"overwrite" {
			try { $set = [Environment]::SetEnvironmentVariable($envvar,$value,$type) }
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished scriptblock action - $name" }
		}
		"clear" {
			try { $set = [Environment]::SetEnvironmentVariable($envvar,"",$type) }
			catch { WriteLog "Error - $($_.Exception.Message) $($_.InvocationInfo.PositionMessage)" }
			finally { WriteLog "Finished scriptblock action - $name" }
		}
	}
}
#END FUNCTIONS

$ErrorActionPreference = "Stop"	

#  Begin file downloads from S3
$wc = New-Object System.Net.WebClient

$dateBlock = { Get-Date -Format "MM/dd/yyyy HH:mm:ss" }

if (!(Test-Path $logFile)) { New-Item $logFile -ItemType File -Force | Out-Null }

if (!(Test-Path $regKey)) { New-Item $regKey -Force | Out-Null }

WriteLog "Beginning Actions"
WriteLog ""

$srcManifest = "{0}/{1}" -f $bucket,$manifest
$localManifest = "{0}\{1}" -f $tempFolder,$manifest

CreateDirectory $tempFolder "manifest"
DownloadFile $srcManifest $tempFolder "manifest"

[xml]$xmlConfig = gc $localManifest

$xmlAppKits = $xmlConfig.APPKITS.APPKIT

foreach ($xmlAppKit in $xmlAppKits) {

	$xmlName		= $xmlAppKit.NAME
	$xmlSrcRepos	= $xmlAppKit.REPOSITORY
	$xmlTools		= $xmlAppKit.TOOLS
	$xmlConfigItems	= $xmlAppKit.CONFIGITEMS
	$xmlTemp		= $xmlAppKit.TEMP
	$xmlDestination	= $xmlAppKit.DESTINATION
	
	$xmlSrcReposName		= $xmlSrcRepos.NAME
	$xmlSrcReposPath		= $xmlSrcRepos.PATH
	$xmlTempFolder			= $xmlTemp.PATH
	$xmlLocalDestination	= $xmlDestination.PATH	

	WriteLog "Starting action $xmlName"
	WriteLog "Repository - $xmlSrcReposName"
	WriteLog "Repository path - $xmlSrcReposPath"
	WriteLog "Local temp path - $xmlTempFolder"

	#-----local temp

	CreateDirectory $xmlTempFolder $xmlName
	CreateDirectory $xmlLocalDestination $xmlName

	#-----

	foreach($xmlTool in $xmlTools.TOOL)
	{
		$srcFile	= $null
		$destFolder	= $null
		
		$xmlToolName		= $xmlTool.NAME
		$xmlToolVer			= $xmlTool.VER
		$xmlToolFilename	= $xmlTool.FILENAME
		$xmlToolAction		= $xmlTool.ACTION
		$xmlToolDownload	= $xmlTool.DOWNLOAD
		$xmlToolRunType		= $xmlTool.RUNTYPE
		
		WriteLog "Tool     - $xmlToolName"
		WriteLog "Action   - $xmlToolAction"
		WriteLog "Run Type - $xmlToolRunType"
		
		#-----Download source file
		
		$xmlSrcFolder	= $xmlTool.REPOPATH
		$xmlSrcFileName	= $xmlTool.FILENAME
		
		if ($xmlSrcFolder) {	$srcFile	= "{0}/{1}/{2}" -f $xmlSrcReposPath,$xmlSrcFolder,$xmlSrcFileName }
		else {					$srcFile	= "{0}/{1}" -f $xmlSrcReposPath,$xmlSrcFileName }
		if ($xmlSrcFolder) {	$destFolder	= "{0}\{1}" -f $xmlLocalDestination,$xmlSrcFolder }
		else {					$destFolder	= $xmlLocalDestination }
		
		$destFilePath = "{0}\{1}" -f $destFolder, $xmlSrcFileName
			
		CreateDirectory $destFolder $xmlToolName
	
		if ($xmlToolDownload -eq "TRUE") { DownloadFile $srcFile $xmlTempFolder $xmlToolName }
		
		#-----
		
		switch($xmlToolAction) {
			"install" {
				#-----process installs

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					if (!(Test-Path "C:\RSTools")) { CreateDirectory "C:\RSTools" "RSToolsDir" }
					
					$srcType 		= [System.IO.Path]::GetExtension($xmlSrcFileName).TrimStart(".")

					$installerPath	= "{0}\{1}" -f $xmlTempFolder, $xmlSrcFileName

					switch($srcType) {
						"exe" {
							$cmdToRun 		= $installerPath
							$cmdSwitches	= $xmlTool.ARGS
							
							InstallApp $cmdToRun $cmdSwitches $xmlToolName
						}
						"msi" {
							$cmdToRun		= "msiexec"
							$cmdSwitches	= "{0} /lv* C:\RSTools\{1}.log" -f $xmlTool.ARGS, $xmlToolName
							$cmdArgs		= "/i$installerPath $cmdSwitches"
							
							InstallApp $cmdToRun $cmdArgs $xmlToolName
						}
						default { WriteLog "Tool $xmltoolName is will only process .exe and .msi files and will not proceed." }	
					}
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}
			
			"filecopy" {
				#-----process file copies

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					if ($xmlToolDownload -eq "TRUE") {
						if ($xmlTool.DESTINATION) { $destFilePath = "{0}\{1}" -f $xmlTool.DESTINATION, $xmlToolFilename }
						
						$srcFile = "{0}\{1}" -f $xmlTempFolder, $xmlToolFilename
						
						CopyFile $srcFile $destFilePath $xmlToolName
					}
					else {
						$xmlToolSource	=$xmlTool.SOURCE
						$xmlToolDest	= $xmlTool.DESTINATION
						
						$srcFile = "{0}\{1}" -f $xmlToolSource, $xmlToolFilename
						$dstFile = "{0}\{1}" -f $xmlToolDest, $xmlToolFilename
						
						CopyFile $srcFile $dstFile $xmlToolName
					}
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}
			
	   		"registry" {
				#-----process registry updates

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlRegKeyPath	= $xmlTool.PATH
					$xmlRegKeyName	= $xmlTool.KEYNAME
					$xmlRegKeyValue	= $xmlTool.VALUE
					$xmlRegKeyType	= $xmlTool.TYPE
					
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}
			
			"commandline" {
				#-----process command line applications

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlSrcFolder	= $xmlTool.PATH
					$xmlFilename	= $xmlTool.FILENAME
					$cmdSwitches	= $xmlTool.ARGS
									
					if ($xmlTool.WORKINGFOLDER) { $wrkFolder = $xmlTool.WORKINGFOLDER }

					StartCommandline $xmlSrcFolder $xmlFilename $cmdSwitches $xmlToolName $wrkFolder
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}

			"service" {
				#-----process service manipulations

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlToolSrvc	= $xmlTool.SERVICE
					$xmlToolCmd		= $xmlTool.COMMAND
					
					ManipulateService $xmlToolSrvc $xmlToolCmd $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}

			"replacetext" {
				#-----process text replacements

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlToolFind	= $xmlTool.FIND
					$xmlToolReplace	= $xmlTool.REPLACE

					$xmlReplaceFile	= "{0}\{1}" -f $xmlTool.PATH, $xmlTool.FILENAME
					
					ReplaceText $xmlReplaceFile $xmlToolFind $xmlToolReplace $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}

			"inserttext" {
				#-----process text insertions

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlText = $xmlTool.TEXT
					$xmlLine = $xmlTool.LINE

					$xmlInsertFile = "{0}\{1}" -f $xmlTool.PATH, $xmlTool.FILENAME
					
					InsertText $xmlInsertFile $xmlText $xmlLine $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}

			"scriptblock" {
				#-----process powershell script blocks

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlScriptBlock = $xmlTool.SCRIPTBLOCK
					
					ExecuteScriptBlock $xmlScriptBlock $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}

			"uncompress" {
				#-----process file uncompression

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

					$xmlSource = $xmlTool.SOURCE
					$xmlDestination = $xmlTool.DESTINATION
					
					Uncompress $xmlSource $xmlDestination $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}

			"modifyenvvar" {
				#-----process environment variable manipulations

				$keyValue = ValidateRun $xmlToolName $xmlToolRunType

				if ($keyValue) {
				
					UpdateRegistry $xmlRegKeyPath $xmlRegKeyName $xmlRegKeyValue $xmlRegKeyType $xmlToolName

				 	$xmlEnvVar		= $xmlTool.ENVVAR
					$xmlEnvType		= $xmlTool.ENVTYPE
					$xmlEnvAction	= $xmlTool.ACTION
					$xmlEnvValue	= $xmlTool.ENVVALUE

					ModifyEnvVar $xmlEnvVar $xmlEnvType $xmlEnvAction $xmlEnvValue $xmlToolName
				}
				else { WriteLog "Tool $xmltoolName is set to $xmlToolRunType and will not proceed." }
			}
		}
	}
	WriteLog ""
	WriteLog "Completed All Actions: Exiting"
}