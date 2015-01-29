param (
	[string]$list = "list.txt",
	[switch]$csv
)

$list = gc $list

$cred = Get-Credential

$data = $list | % { gwmi -query "SELECT NetConnectionID,NetConnectionStatus,Name,SystemName FROM Win32_NetworkAdapter WHERE NOT (Name LIKE 'WAN%' OR Name LIKE 'RAS%' OR Name LIKE 'Microsoft%' OR Name LIKE 'Direct Parallel%')" -computer $_ -cred $cred } |	Select `
	@{Name="Server";Expression={[System.Net.Dns]::GetHostByName($_.SystemName).HostName}},`
	@{Name="NIC";Expression={$_.NetConnectionID}},`
	@{Name="Disabled";Expression={if ($_.NetConnectionStatus -eq 0) { $true } else { $false }}},`
	@{Name="Hardware";Expression={$_.Name}}


$count = foreach ($server in ($data | Select -Unique -ExpandProperty Server)) {
	$disabled = 0
	$enabled = 0
	
	$data | ? {
		$_.Server -match $server
	} | % {
		if ($_.Disabled -eq $true) {
			$disabled += 1
		}
		elseif ($_.Disabled -eq $false) {
			$enabled += 1
		}
	}
	
	"" | Select `
		@{Name="Server";Expression={$server}},`
		@{Name="Disabled";Expression={$disabled}},`
		@{Name="Enabled";Expression={$enabled}}
}

if ($csv) {
	$data | Export-Csv .\Nics.csv -notype
	$count | Export-Csv .\DisabledCount.csv -notype
}

else {
	$data
	$count
}