param (
	[string]$address, #single address or DNS name to query
	[string]$file #file with a list of addresses or DNS names to query, other than list.txt"
)
if ($file) { $list = Get-Content $file }
else { $list = Get-Content "list.txt" }
$myObj = @()
if ($address -ne "") {
	$myCol = "" | Select Server,MAC
	$nbtstat = nbtstat -a $address
	$notfound = $nbtstat | Select-String "    Host not found."
	if (!$nbtstat) { Write-Host "You must be an admin on this machine to run the query." ; $MAC = "ERROR"}
	elseif ($notfound) { $MAC = "unknown" }
	else { $MAC = ((($nbtstat | Select-String "MAC Address").ToString()).Split("`=")[1]).Replace(" ","") }
	$myCol.Server = $address
	$myCol.MAC = $MAC
	$myObj += $myCol
} else {
	foreach ($address in $list) {
		$myCol = "" | Select Server,MAC
		$nbtstat = nbtstat -a $address
		$notfound = $nbtstat | Select-String "    Host not found."
		if (!$nbtstat) { Write-Host "You must be an admin on this machine to run the query." ; $MAC = "ERROR"}
		elseif ($notfound) { $MAC = "unknown" }
		else { $MAC = ((($nbtstat | Select-String "MAC Address").ToString()).Split("`=")[1]).Replace(" ","") }
		$myCol.Server = $address
		$myCol.MAC = $MAC
		$myObj += $myCol
	}
}
$myObj | Select Server,MAC