param (
	[string] $app, # app name to search for
	[string] $file, # specifies a list file other than list.txt
	[string] $filter, # app names to filter out
	[string] $out, # alternate name for the output file
	[string] $server, # single server to query
	[switch] $console, # output to the console instead of CSV
	[switch] $user # specify credentials
)

Write-Host "Started:" (Get-Date -Format HH:mm:ss)

if ($out -eq "") { $out = "Get-InstalledApps.csv" }
if ($file -ne "") { $list = Get-Content $file }
elseif ($server -ne "") {$list = $server }
else { $list = Get-Content "list.txt" }

$ping = New-Object System.Net.NetworkInformation.Ping	

if ($user) { $cred = Get-Credential }

$data = @()

if ($list.Count) { $total = $list.Count }
else { $total = "1" }

Write-Host "Gathering information for:"
$count = 0
foreach ($item in $list) {
	$count += 1
	Write-Host "$item  ($count of $total)" -NoNewline
	$reply = $ping.Send($item)
	if ($reply.Status -eq "Success") {
		if ($filter -ne "") {
			if ($app -ne "") {
				if ($cred) { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item -Credential $cred | Where {$_.name -match $app -and $_.name -notmatch $filter} }
				else { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item | Where {$_.name -match $app -and $_.name -notmatch $filter} }
			} else {
				if ($cred) { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item -Credential $cred | Where {$_.name -notmatch $filter} }
				else { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item | Where {$_.name -notmatch $filter} }
			}
		} else {
			if ($app -ne "") {
				if ($cred) { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item -Credential $cred | Where {$_.name -match $app} }
				else { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item | Where {$_.name -match $app} }
			} else {
				if ($cred) { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item -Credential $cred | }
				else { $wmiProduct = Get-WmiObject -Namespace Root\CIMV2 -Class Win32_Product -ComputerName $item}
			}
		}
		foreach ($wmiApp in $wmiProduct) {
			$row = "" | Select Server,Application,Version,Vendor
			$row.Server = $item.ToUpper()
			if ($wmiApp) {
				$row.Application = $wmiApp.Name
				$row.Version = $wmiApp.Version
				$row.Vendor = $wmiApp.Vendor
			} else { $row.Application = "$app is not installed " }
			$data += $row
			$wmiApp = ""
		}
	} else {
		$row = "" | Select Server,Application,Version,Vendor
		$row.Server = $item.ToUpper()
		$row.Application = $reply.Status
		$data += $row
	}
	Write-Host ""
}
if ($console) { $data | Format-List }
else { $data | Export-Csv $out -NoTypeInformation }

Write-Host "Finished:" (Get-Date -Format HH:mm:ss)