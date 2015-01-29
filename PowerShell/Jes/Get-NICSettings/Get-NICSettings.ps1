# Get-NICSettings by Hugo Peeters of www.peetersonline.nl
#########################################################
if ($args) { $server = $args[0] }
else { $server = Read-Host "Enter server name" }

$nics = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $server
$links = get-wmiobject -class "MSNdis_LinkSpeed" -namespace "root\WMI" -computername $server | Where { $_.Active -Match "True" }
$row = "" | Select-Object Description,DHCPEnabled,IPAddress,IPSubnet,DefaultIPGateway,DNSServers,WINSServers,Speed,Duplex,LinkSpeed

$registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $server)
$baseKey = $registry.OpenSubKey("SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}")

ForEach ($nic in $nics) {
	If ($nic.IPAddress -ne $null) {
		$row.Description = $nic.Description
		$row.DHCPEnabled = $nic.DHCPEnabled
		$row.IPAddress = $nic.IPAddress
		$row.IPSubnet = $nic.IPSubnet
		$row.DefaultIPGateway = $nic.DefaultIPGateway
		$row.DNSServers = $nic.DNSServerSearchOrder
		$row.WINSServers = $nic.WINSPrimaryServer,$nic.WINSSecondaryServer
		$subKeyNames = $baseKey.GetSubKeyNames()
		foreach ($subKeyName in $subKeyNames) {
			$subKey = $baseKey.OpenSubKey("$subKeyName")
			$ID = $subKey.GetValue("NetCfgInstanceId")
			if ($ID -eq $nic.SettingId)	{
				$componentID = $subKey.GetValue("ComponentID")
				$driverDesc = $subKey.GetValue("DriverDesc")
				if ($componentID -match "ven_14e4") {
					$SD = $subKey.GetValue("RequestedMediaType")
					$enum = $subKey.OpenSubKey("Ndi\Params\RequestedMediaType\Enum")
					$sdValue = $enum.GetValue("$SD")
				} elseif ($componentID -match "ven_1022") {
					$SD = $subKey.GetValue("EXTPHY")
					$enum = $subKey.OpenSubKey("Ndi\Params\EXTPHY\Enum")
					$sdValue = $enum.GetValue("$SD")
				} elseif ($componentID -match "ven_8086") {
					$SD = $subKey.GetValue("SpeedDuplex")
					$enum = $subKey.OpenSubKey("Ndi\savedParams\SpeedDuplex\Enum")
					$enum1 = $subKey.OpenSubKey("Ndi\Params\SpeedDuplex\Enum")
					if ($enum) { $sdValue = $enum.GetValue("$SD") }
					elseif ($enum1) { $sdValue = $enum1.GetValue("$SD") }
				} elseif ($componentID -match "b06bdrv") {
					$specialSD = @"
*SpeedDuplex
"@
					if ($subKey.GetValue($specialSD)) { $SD = $subKey.GetValue($specialSD) }
					else { $SD = $subKey.GetValue("req_medium") }
					$enum = $subKey.OpenSubKey("Ndi\Params\req_medium\Enum")
					$enum1 = $subKey.OpenSubKey("BRCMndi\params\req_medium\Enum")
					$enum2 = $subKey.OpenSubKey("BRCMndi\params\$specialSD\Enum")
					if ($enum) { $sdValue = $enum.GetValue("$SD") }
					elseif ($enum1) { $sdValue = $enum1.GetValue("$SD") }
					elseif ($enum2) { $sdValue = $enum2.GetValue("$SD") }
				} elseif ($driverDesc -match "VMWare") {
					$SD = $subKey.GetValue("EXTPHY")
					$enum = $subKey.OpenSubKey("Ndi\Params\EXTPHY\Enum")
					$sdValue = $enum.GetValue("$SD")
				} Else { $sdValue = "unknown" }
				write-host "Speed/Duplex:" $sdValue
				if ($sdValue -eq "Hardware Default") {
					$speed = $sdValue
					$duplex = $sdValue
				} elseif ($sdValue -eq "") {
					$speed = "unknown"
					$duplex = "unknown"
				} else {
					$sdSplit = $sdValue.Split("`/")
					$sdSplit1 = $sdValue.Split(" ")
					if ($sdSplit.Count -gt 1) {
						$speed = $sdSplit[0]
						$duplex = $sdSplit[1]
					} elseif ($sdSplit.Count -gt 1 -and $sdSplit -notcontains "auto") {
						$speed = $sdSplit[0]
						$duplex = $sdSplit[1]
					} elseif ($sdSplit1.Count -gt 1 -and $sdSplit1[2]) {
						$speed = $sdSplit1[0] + " " + $sdSplit1[1]
						$duplex = $sdSplit1[2] + $sdSplit1[3]
					} else {
						$speed = $sdValue
						$duplex = $sdValue
					}
				}
			}
		}
		$row.Speed = $speed
		$row.Duplex = $duplex
		$nicDesc = ((($nic.Description).Replace("`(","")).Replace("`)","")).Replace("`/","")
		foreach ($link in $links) {
			$linkInst = ((($link.InstanceName).Replace("`(","")).Replace("`)","")).Replace("`/","")
			if ($linkInst -match $nicDesc) {
				$connectedSpeed = $link.NdisLinkSpeed
				if ($connectedSpeed -eq 10000000) { $connectedSpeed = "1Gbps" }
				elseif ($connectedSpeed -eq 1000000) { $connectedSpeed = "100Mbps" }
				else { $connectedSpeed = "uncommon" }
				$found = $TRUE
			} elseif ($found) {  }
			else {$connectedSpeed = "unknown" }
		}
		$found = $FALSE
		$row.LinkSpeed = $connectedSpeed
	}
}
$row