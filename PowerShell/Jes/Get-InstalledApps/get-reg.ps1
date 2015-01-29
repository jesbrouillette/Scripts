$Srv = "xlwicht77m"
$key = "SOFTWARE\Citrix\IMA\RUNTIME"
$type = [Microsoft.Win32.RegistryHive]::LocalMachine
$regKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Srv)
$regKey = $regKey.OpenSubKey($key)
Write-Host "Sub Keys"
Write-Host "--------"
Foreach($sub in $regKey.GetSubKeyNames()){$sub}
Write-Host
Write-Host "Values"
Write-Host "------"
Foreach($val in $regKey.GetValueNames()){$val}
