$ErrorActionPreference = "SilentlyContinue"
$list = GC "list.txt"
$data = @()
foreach ($item in $list) {
	$objNics = GWMI Win32_NetworkAdapterConfiguration -ComputerName $item -Filter "IPEnabled=True"
	foreach ($objNic in $objNics) {
		if ($objNic.IPAddress -ne "0.0.0.0") {
			$WINS = @()
			$WINS += $objNic.WINSPrimaryServer
			$WINS += $objNic.WINSSecondaryServer
			$row = "" | Select Server,NIC,DHCP,IP,DNS,WINS
			$row.Server = $objNic.DNSHostName + "." + $objNic.DNSDomain
			$row.NIC = $objNic.Description
			$row.DHCP = $objNic.DHCPEnabled
			$row.IP = $objNic.IPAddress
			$row.DNS = $objNic.DNSServerSearchOrder
			$row.WINS = $WINS
	
			$row | FL *
		}
	}
}