$ErrorActionPreference = "Continue"
$data = @()

$nics = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" | Where { $_.IpEnabled -Match "True" -and $_.IPAddress -ne "0.0.0.0" }
$links = get-wmiobject -class "MSNdis_LinkSpeed" -namespace "root\WMI" | Where { $_.Active -Match "True" }

$expression = "racadm setniccfg -d"
$invoke = Invoke-Expression $expression
if ($invoke -match "ENABLED") { $DRACDHCP = $true }
else { $DRACDHCP = $false }

$expression = "racadm config -g cfgLanNetworking -o cfgDNSRacName " + $env:COMPUTERNAME + "-rc"
$invoke = Invoke-Expression $expression
if ($invoke -match "object value modified successfully") { $DRACDNSChange = $true }
else { $DRACDNSChange = $false }

$expression = "racadm racreset"
$invoke = Invoke-Expression $expression
$RACReset = $true

Write-Host "Waiting 60 sec for the DRAC to reset..."
Start-Sleep -Seconds 60

$expression = "nbtstat -R"
$invoke = Invoke-Expression $expression
if ($invoke -contains "successful") { $NBTRefresh = $true }
else { $NBTRefresh = $false }

$expression = "nbtstat -RR"
$invoke = Invoke-Expression $expression
if ($invoke -contains "have been refreshed.") { $WINSRefresh = $true }
else { $WINSRefresh = $false }

$expression = "ipconfig /flushdns"
$invoke = Invoke-Expression $expression
if ($invoke -contains "Successfully") { $FlushDNS = $true }
else { $FlushDNS = $false }

$expression = "ipconfig /registerdns"
$invoke = Invoke-Expression $expression
if ($invoke -contains "has been initiated") { $RegisterDNS = $true }
else { $RegisterDNS = $false }

$expression = "racadm getsysinfo"
$invoke = Invoke-Expression $expression
foreach ($item in $invoke) {
	if ($item -match "current ip address") {
		$dracip = ($item.Split("=")[1]).Replace(" ","")
	}
}

foreach ($nic in $nics) {
	$row = "" | Select Nic,Speed,DRACIP,DRACDHCP,DRACDNSChange,RACReset,NBTRefresh,WINSRefresh,FlushDNS,RegisterDNS
	$nicDesc = ((($nic.Description).Replace("`(","")).Replace("`)","")).Replace("`/","")
	foreach ($link in $links) {
		$linkInst = ((($link.InstanceName).Replace("`(","")).Replace("`)","")).Replace("`/","")
		if ($linkInst -match $nicDesc) {
			$Speed = $link.NdisLinkSpeed
			if ($Speed -eq 10000000) { $Speed = "1Gbps" }
			elseif ($Speed -eq 1000000) { $Speed = "100Mbps" }
			else { $Speed = "uncommon" }
			$found = $TRUE
		} elseif ($found) {  }
		else { $Speed = "unknown" }
	}
	$found = $FALSE
	
	$row.Nic = $nicDesc
	$row.Speed = $Speed
	$row.DRACIP = $dracip
	$row.DRACDHCP = $DRACDHCP
	$row.DRACDNSChange = $DRACDNSChange
	$row.RACReset = $RACReset
	$row.NBTRefresh = $NBTRefresh
	$row.WINSRefresh = $WINSRefresh
	$row.FlushDNS = $FlushDNS
	$row.RegisterDNS = $RegisterDNS
	$data += $row
}
$data | fl *