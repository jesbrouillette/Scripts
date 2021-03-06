param (
	[string]$source			= $ENV:INST_SOURCE,
	[string]$destination	= $ENV:INST_DESTINATION,
	[string]$logDir			= $ENV:INST_LOGDIR
)

if (!$source) 		{ $source		= "http://windows.php.net/downloads/releases/php-5.3.28-nts-Win32-VC9-x86.msi" }
if (!$destination)	{ $destination	= "C:\Temp\" }
if (!$logDir)		{ $logDir		= "C:\RSTools\Logs\" }

if ($destination[$destination.Length-1] -ne "\")	{ $destination	+= "\" }
if ($logDir[$logDir.Length-1] -ne "\")				{ $logDir		+= "\" }


#--VARs
[string]$installer		= $source.Split("/")[-1]
[string]$cmd			= "{0}{1}" -f $destination,$installer
[string]$cmdArgs		= "/q /norestart /lvx+ {0}{1}.log" -f $logDir,$($installer.Substring(0,$installer.Length-4))
[string]$logFile		= "{0}.log" -f $($MyInvocation.MyCommand.Name.Trim(".ps1"))
[string]$log			= "{0}{1}" -f $logDir,$logFile

[scriptblock]$dateBlock	= { Get-Date -Format "MM/dd/yyyy HH:mm:ss" }

$wc = New-Object System.Net.WebClient

function WriteLog {
	param (
		$text
	)
	$logText = "{0}: {1}" -f $(&$dateBlock),$text
	
	Write-Host $logText
	Write-Output $logText | Add-Content $log -Force
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
	
	if ($destination[-1] -ne "\") { $destination = $destination + "\" + $file }
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

if (!(Test-Path -path $destination)) { New-Item $destination -Type Directory }
if (!(Test-Path -path $logDir)) { New-Item $logDir -Type Directory }
if (!(Test-Path $log)) { New-Item $log -ItemType File -Force | Out-Null }

DownloadFile $source $destination "PHP 5.3 Download"

InstallApp $cmd $cmdArgs "PHP 5.3 Installer"