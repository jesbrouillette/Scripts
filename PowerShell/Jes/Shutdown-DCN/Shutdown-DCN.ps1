param (
	[string]$file,		# file to import other than list.txt
	[string]$server,	# change a single server
	[string]$old,		# old ip
	[string]$new,		# new ip
	[string]$action,	# change type (add or replace ip)
	[switch]$help		# displays console help message
)

function OpSysPower($intPowerOpt) { #Initiates the shutdown or reboot sequence using WMI
	if (!$local) {
		$opSys = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server
	} else {
		$opSys = Get-WmiObject -Class Win32_OperatingSystem
		$powerCycle = $opSys.Win32Shutdown($intPowerOpt,0)
		exit
	}
	$powerCycle = $opSys.Win32Shutdown($intPowerOpt,0)
	$now = Get-Date -Format "h:mm:ss tt"
	if (!$q) { Write-Host  "power sequence initiated at" $now }
}

$subnet = "255.255.255.0"
$dns = "10.2.104.11","10.2.204.11","10.2.218.12"
$wins = "10.2.59.109","10.2.218.21"

$nics = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" -computername "." -Filter "IpEnabled='True'"

foreach ($item in $list) {
	$ips = @()
	$item = $item.Replace(" ","")
	foreach ($nic in $nics) {
		if ($nic.IPAddress -match $item.old) {
			$gateway = [string]::join(".",($item.new.split(".")[0..2])) + ".1"
			$nic.SetGateways($gateway,1)
			if ($nic.DHCPEnabled -ne "FALSE") {
				$nic.EnableStatic($item.new,$subnet)
				$nic.EnableDNS()
				$nic.SetDNSServerSearchOrder($dns)
				$nic.SetWINSServer($wins)
			}
			elseif ($item.Action -eq "add") {
				$ips = $nic.IPAddress + $item.New
				$nic.EnableStatic($ips,$subnet)
			}
			elseif ($item.Action -eq "replace") {
				$nic.EnableStatic($item.new,$subnet)
			}
		}
	}
}