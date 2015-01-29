Param (
	[string]$list = "list.txt",
	[switch]$cred
)

gc $list | % {
	if ($cred) { $wmiDisk = get-wmiobject -class "Win32_LogicalDisk" –credential $cred -computername $item -filter "drivetype=3" }
	else { $wmiDisk = get-wmiobject -class "Win32_LogicalDisk" -computername $item -filter "drivetype=3" }
	$wmiDisk | Select `
		@{Name="Device";Expression={$_.SystemName}},`
		@{Name="Disk";Expression={$_.Caption}},`
		@{Name="Size";Expression={[Math]::round(($_.Size / 1GB),2)}},`
		@{Name="Used Space";Expression={[Math]::round(($_.Size / 1GB) - ($_.FreeSpace / 1GB),2)}},`
		@{Name="Free Space";Expression={[Math]::round(($_.FreeSpace / 1GB),2)}},`
		@{Name="Precent Free Space";Expression={[Math]::Truncate((($_.FreeSpace / 1Gb)/($_.Size / 1GB)) * 100)}}
}