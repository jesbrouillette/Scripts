function OutZip ([string]$path) { 
	[System.Int32]$yesToAll = 16
	
	if (-not $path.EndsWith('.zip')) {$path += '.zip'} 

	if (-not (test-path $path)) { 
		set-content $path ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18)) 
		(dir $path).IsReadOnly = $false
	} 
	$ZipFile = (new-object -com shell.application).NameSpace($path) 
	$input | foreach {$zipfile.CopyHere($_.fullname,$yesToAll)} 
}

#------------------------
# set autoconfig url in IE
#------------------------
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
$autoconfig = "HTTP://PAC.US.PROXY.CARGILL.COM:4200/PROXY.PAC"
$remove = remove-itemproperty -path $path -name AutoConfigURL
$set = set-itemproperty -path $path -name AutoConfigURL -value $autoconfig.ToUpper()
$autoconfigset = get-itemproperty -path $path -name AutoConfigURL
write-host IE\AutoConfigURL is now set to $autoconfigset.AutoConfigURL

#------------------------
# verify startup
#------------------------
$strStartup = Read-Host -Prompt "Do you want to load startup items?"
$strBackup = Read-Host -Prompt "Do you want to backup items?"

#------------------------
# set startup items
#------------------------
if ($strStartup -like "y*") {
	$visionapp = Invoke-Item "C:\Documents and Settings\jebrouil.na\Start Menu\Programs\visionapp Remote Desktop\visionapp Remote Desktop.lnk"
	Start-Sleep -Seconds 10
	$ipcommunicator = "C:\Documents and Settings\All Users\Start Menu\Programs\Cisco IP Communicator\Cisco IP Communicator.lnk"
	Start-Sleep -Seconds 10
	$outlook = Invoke-Item "C:\Program Files\Microsoft Office\Office12\OUTLOOK.EXE"
	Start-Sleep -Seconds 10
	$sametime = Invoke-Item "C:\Program Files\IBM\Lotus\Sametime Connect\rcp\rcplauncher.exe"
}

if ($strBackup -like "y*") {
	Get-ChildItem "C:\ittools\Scripting" -Exclude "*.log","*.txt" | OutZip "p:\ittools\s_archive.zip"
}

cls
.$profile