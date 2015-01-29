#Get the current domain name
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
#Create the query string.
$query = "Select IPAddress,OwnerName from MicrosoftDNS_AType WHERE DomainName='$($domain)'"
#Retrieve the DNS data desired
$data = gwmi -namespace "root\MicrosoftDNS" -query $query -ComputerName $domain | Select IPAddress,OwnerName | ? { $_.OwnerName -ne $domain }

$hash = @{}
#Find all duplicated IPs
$data | % {$hash[$_.IPAddress] = $hash[$_.IPAddress] + 1 }
$ips = $hash.GetEnumerator() | ? { $_.value -gt 1 } | Select -Expand Name

$hash.Clear()
#Find all duplicated names
$data | % {$hash[$_.OwnerName] = $hash[$_.OwnerName] + 1 }
$machines = $hash.GetEnumerator() | ? { $_.value -gt 1 } | Select -Expand Name

#Display the data
$data | Select IPAddress,OwnerName,@{Name="Unique";Expression={($ips -notcontains $_.IPAddress -and $machines -notcontains $_.OwnerName)}} | Sort IPAddress
