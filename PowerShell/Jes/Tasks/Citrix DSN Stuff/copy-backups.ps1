$list = Get-Content $args[0]
$location = "c:\Program Files\Citrix\Independent Management Architecture\MF20-180209.bak"

foreach ($server in $list) {
	$backup_file = "\\" + $server + "\" + $location -replace ":","$"
	$copy = $server + "-MF20-180209.bak"
	$copy_to = "C:\Temp\CTX\MF20s\" + $copy

	if ((Test-Path -Path $oldbackup_location) -eq $false) {
		$create_oldbackup= Copy-Item -Path $backup_file -Destination $copy_to
	}
}