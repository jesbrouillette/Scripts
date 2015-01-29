$erroractionpreference = "SilentlyContinue"

$Start = Get-Date
Write-Host "Started:" $Start.ToString()
$list = New-Object System.Collections.ArrayList
$farm = new-Object -com "MetaframeCOM.MetaframeFarm"
$farm.Initialize(1) | Out-Null

$servers = $farm.Servers

Write-Host $farm.FarmName "contains" $servers.Count "servers"
$out = $farm.FarmName + ".txt"

foreach($server in $servers) {
	$reported += 1
	if ($farm.FarmName -match "cps_farm") {
		$server.LoadData($True)
	}
	$list.Add($server.ServerName)
	if (($reported % 15) -eq 0 -or $reported -eq $servers.Count -and $reported -ne 0) {
		Write-Host " " $reported "of" $servers.Count "servers reported"
	}
}

$list | Out-File $out -Encoding ASCII
$End = Get-Date
Write-Host "Finished:" $End.ToString()
Write-Host "Runtime:" ($End - $Start)