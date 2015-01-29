Param (
	[string]$Computer
)
if (Test-Connection $Computer -Count 1 -Quiet) {
	$IPInfo = gwmi -query "Select MACADDRESS FROM Win32_NetworkAdapterConfiguration WHERE IpEnabled='True'" -ComputerName $Computer
	$SerialNumber = (gwmi -Query "Select SerialNumber FROM Win32_BIOS" -ComputerName $Computer).SerialNumber
	"" | Select @{Name="Name";Expression={$Computer}},`
		@{Name="MACAddress";Expression={$IPInfo | Select -ExpandProperty MACAddress}},`
		@{Name="SerialNumber";Expression={$SerialNumber}}
}
else {
	"" | Select @{Name="Name";Expression={$Computer}},@{Name="MACAddress";Expression={"Unknown"}},@{Name="SerialNumber";Expression={"Unknown"}}
}