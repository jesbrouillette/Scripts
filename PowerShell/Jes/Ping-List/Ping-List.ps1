param (
	[string]$list = "list.txt",	# list of devices to ping
	[switch]$os						# query for OS version.  only works on windows devices
)

$erroractionpreference = "SilentlyContinue"

$devices = get-content $list

if ($os) {
	$cred = Get-Credential
}

$count = $devices.count
$reported = 0

$responce = New-Object system.Data.DataTable "responce" # Setup the Datatable Structure
$col1 = New-Object system.Data.DataColumn queried,([string])
$col2 = New-Object system.Data.DataColumn status,([string])
$col3 = New-Object system.Data.DataColumn ip,([string])
$col4 = New-Object system.Data.DataColumn hostname,([string])
if ($os) {
	$col5 = New-Object system.Data.DataColumn os,([string])
}

$responce.columns.add($col1)
$responce.columns.add($col2)
$responce.columns.add($col3)
$responce.columns.add($col4)
if ($args[1] -eq "-os") {
	$responce.columns.add($col5)
}

Write-Host $count "objects to query"

foreach ($device in $devices) {
	$reported += 1
	
	$timeout=120;
	$ping = new-object System.Net.NetworkInformation.Ping
	$reply = $ping.Send($device,$timeout)

	if ($reply.status –eq "Success") {
		$ip = ($ping.send($device).address).ipaddresstostring
		$hostname = ([System.Net.Dns]::GetHostbyAddress($ip)).HostName
		if ($args[1] -eq "-os") {
			$os = (Get-WmiObject Win32_OperatingSystem -Credential $cred -ComputerName $hostname).Caption
			if (!$os) {
				$os = "Unknown"
			}
		}
	}
	else {
		$ip = "Unknown"
		$hostname = "Unknown"
		$os = "Unknown"
	}

	$row = $responce.NewRow()
	$row.queried = $device
	$row.status = $reply.status
	$row.ip = $ip
	$row.hostname = $hostname
	if ($args[1] -eq "-os") {
		$row.os = $os
	}
	$responce.Rows.Add($row)

	if (($reported % 5) -eq 0 -or $reported -eq $count -and $reported -ne 0) {
		Write-Host " " $reported "of" $count "objects queried"
	}

}

$responce | foreach {$_} | where {$_.Status -eq "Success"}

$out = $responce | Export-Csv -NoTypeInformation -Path ("Ping_" + (Get-Date -Format dd-MM-hh-mm) + ".csv")