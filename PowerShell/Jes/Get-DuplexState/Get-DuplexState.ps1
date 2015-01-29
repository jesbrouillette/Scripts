param (
	[string]$server
)

$ErrorActionPreference = "SilentlyContinue"

$nics = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $server | ? { $_.IPEnabled -eq "True" }
$registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $server)
$baseKey = $registry.OpenSubKey("SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}")

$data = @()

foreach ($nic in $nics) {
	if ($nic.Description -match "Intel") { $intel = $true }
	elseif ($nic.Description -match "Broadcom") { $broadcom = $true	}
	elseif ($nic.Description -match "AMD PCNET Family" {
		$subKeyNames = $baseKey.GetSubKeyNames()
		foreach ($subKeyName in $subKeyNames) {
			$subKey = $baseKey.OpenSubKey("$subKeyName")
			$ID = $subKey.GetValue("NetCfgInstanceId")
			if ($ID -eq $nic.SettingId)	{
				$componentID = $subKey.GetValue("ComponentID")
				$driverDesc = $subKey.GetValue("DriverDesc")
				if (($driverDesc -match "VMWare") -or ($driverDesc -match "AMD")) {
					$SD = $subKey.GetValue("EXTPHY")
					$enum = $subKey.OpenSubKey("Ndi\Params\EXTPHY\Enum")
					$sdValue = $enum.GetValue("$SD")
				}
				$sdSplit = $sdValue.Split("`/")
				$sdSplit1 = $sdValue.Split(" ")
				if ($sdSplit.Count -gt 1) {
					$duplex = $sdSplit[1]
				} elseif ($sdSplit.Count -gt 1 -and $sdSplit -notcontains "auto") {
					$duplex = $sdSplit[1]
				} elseif ($sdSplit1.Count -gt 1 -and $sdSplit1[2]) {
					$duplex = $sdSplit1[2] + $sdSplit1[3]
				} else {
					$duplex = $sdValue
				}
			}
			
			$row = "" | Select Server,NIC,DuplexState,Error
			$row.Server = $server
			$row.NIC = "VM Guest"
			$row.DuplexState = "Full"
			$row.Error = $Error[0].Exception.Message
			$data += $row
			$Error.Clear()
	
	}
}

if ($intel) {
	$intls = gwmi -class "IANet_EthernetAdapter" -Namespace "ROOT\IntelNCS" -ComputerName $server | ? { $_.StatusInfo -eq 3 }
	if ($intls) {
		foreach ($intl in $intls) {
			$row = "" | Select Server,NIC,DuplexState,Error
			if ($intl.FullDuplex -eq $true) { $duplex = "True" }
			else { $duplex = "False" }
			$row.Server = $server
			$row.NIC = $intl.Caption
			$row.DuplexState = $duplex
			$row.Error = 0
			$data += $row
		}
	}
	else {
		$row = "" | Select Server,NIC,DuplexState,Error
		$row.Server = $server
		$row.NIC = "unknown"
		$row.DuplexState = "unknown"
		$row.Error = $Error[0].Exception.Message
		$data += $row
		$Error.Clear()
	}
}

if ($broadcom) {
	$brcms = gwmi -class "BRCM_EthernetPort" -Namespace "ROOT\BrcmBnxNS" -ComputerName $server | ? { $_.LinkStatus -eq 4 }
	if (!$brcms) { $brcms = gwmi -class "BRCM_NetworkAdapter" -Namespace "ROOT\CIMV2" -ComputerName $server | ? { $_.LinkStatus -eq 4 } }
	if ($brcms) {
		foreach ($brcm in $brcms) {
			$row = "" | Select Server,NIC,DuplexState,Error
			if ($brcm.FullDuplex -eq $true) { $duplex = "True" }
			elseif ($brcm.DuplexMode = 3) { $duplex = "True" }
			else { $duplex = "False" }
			$brcm.Description[0]
			if ($brcm.Description[0] -eq "`[") { $description = $brcm.Description.SubString(7) }
			else { $description = $brcm.Description }
			$row.Server = $server
			$row.NIC = $description
			$row.DuplexState = $duplex
			$row.Error = 0
			$data += $row
		}
	}
	else {
		$row = "" | Select Server,NIC,DuplexState,Error
		$row.Server = $server
		$row.NIC = "unknown"
		$row.DuplexState = "unknown"
		$row.Error = $Error[0].Exception.Message
		$data += $row
		$Error.Clear()
	}
}

if ($vmware) { 
}

$data