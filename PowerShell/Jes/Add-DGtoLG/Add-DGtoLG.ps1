param (
	[string]$list
)

$ErrorActionPreference = "Continue"

[object]$list = Import-Csv $list
$log = "Add-DGtoLG_" + (Get-Date -format "MM-dd-yy.HH.mm.ss") + ".log"

Write-Host "Adding" $list.Count "Domain Groups to Local Groups"
$count = 0

foreach ($item in $list) { 
	$count += 1
	$server = $item.Server
	$local = $item.LocalGroup
	$domain = $item.Domain
	$group = $item.DomainGroup
	
	$localGroup = [ADSI]"WinNT://$server/$local,group"
	$localGroup.Add("WinNT://$domain/$group,group")
	
	if ($Error[0]) {
		$msg = "Unable to add " + $domain + "\" + $group + " to " + $server + "\" + $local + "  :  " + $error[0].Exception.Message
		$msg | Out-File $log -Append -Encoding ASCII
		$Error.Clear()
	} else {
		$msg = "Added " + $domain + "\" + $group + " to " + $server + "\" + $local
		$msg | Out-File $log -Append -Encoding ASCII
	}
	
	if (($count % 5) -eq 0 -or $count -eq $list.Count -and $count -ne 0) {
		Write-Host " " $count "of" $list.Count " Domain Groups added to Local Groups"
	}
}