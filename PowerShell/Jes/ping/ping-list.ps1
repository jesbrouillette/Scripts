param (
	[string]$file
)

$erroractionpreference = "SilentlyContinue"

if ($file) { $list = Get-Content $file }
else { $list = Get-Content list.txt }
$myobj = @()

$ping = new-object System.Net.NetworkInformation.Ping

foreach ($item in $list) {
	$row = "" | Select Machine,Response,IP
	$Reply = $ping.send($item)
	$row.Machine = $item.ToUpper()
	if ($Reply.status -eq "DestinationHostUnreachable") { $row.Response = "Unreachable" ; $row.IP = "Unknown" } 
	else { $row.Response = $Reply.Status ; $row.IP = $Reply.Address.ToString() } 
	$Reply = ""
	$myobj += $row
}
$myObj