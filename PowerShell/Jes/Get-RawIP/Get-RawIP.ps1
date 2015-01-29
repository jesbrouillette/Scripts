$erroractionpreference = "SilentlyContinue"

$TextFileLocation=$args[0]
$Credentials=$args[1]

if ($TextFileLocation -eq "") {	
	write-host "Usage:GetRawIP.ps1 machinefilename domain\username";
	exit;
}
elseif ($Credentials -eq "") {
	write-host "Usage:GetRawIP.ps1 machinefilename domain\username";
	exit;
} 
else {
	$cred = get-credential $Credentials
	$InFile = Get-Content "$TextFileLocation"
	foreach($strSrvr in $InFile) {
		$ping = new-object System.Net.NetworkInformation.Ping
		$Reply = $ping.send($strSrvr)
		
		if ($Reply.status –eq "Success") {
			$colItems = get-wmiobject -class "Win32_NetworkAdapterConfiguration" -namespace "root\cimv2" –credential $cred -computername $strSrvr | Where{$_.IPEnabled -Match "True" -and $_.IPAddress -ne "0.0.0.0"}
			
			if ($colItems -ne $null) {
			
				foreach ($objItem in $colItems[0]) {
					$RoundTrip = $Reply.RoundtripTime
					$DNSHostName = $objItem.DNSHostName
					$DNSDomain = $objItem.DNSDomain
					$Description = $objItem.Description
					$MACAddress = $objItem.MACAddress
					$DHCPEnabled = $objItem.DHCPEnabled
					$IPAddress = $objItem.IPAddress
					$IPEnabled = $objItem.IPEnabled
					$DNSServerSearchOrder  = $objItem.DNSServerSearchOrder 
					$WINSPrimaryServer = $objItem.WINSPrimaryServer
					$WINSSecondaryServer = $objItem.WINSSecondaryServer
					$now1 = Get-Date -uFormat %x
					$now2 = Get-Date -Format T
					$now = $now1 + " " + $now2 + ":"
					Write-Output "====================" | Out-File -FilePath log.txt -Append
					Write-Output $now | Out-File -FilePath log.txt -Append
					Write-Output "====================" | Out-File -FilePath log.txt -Append
					Write-Output "Machine Checked : $strSrvr" | Out-File -FilePath log.txt -Append
					Write-Output "Response Time :  $RoundTrip" | Out-File -FilePath log.txt -Append
					Write-Output "DNS Name :  $DNSHostName" | Out-File -FilePath log.txt -Append
					Write-Output "DNS Domain :  $DNSDomain" | Out-File -FilePath log.txt -Append
					Write-Output "MAC Address :  $MACAddress" | Out-File -FilePath log.txt -Append
					Write-Output "DHCP Enabled :  $DHCPEnabled" | Out-File -FilePath log.txt -Append
					Write-Output "IPAddress :  $IPAddress" | Out-File -FilePath log.txt -Append
					Write-Output "IPEnabled :  $IPEnabled" | Out-File -FilePath log.txt -Append
					Write-Output "DNS Server :  $DNSServerSearchOrder" | Out-File -FilePath log.txt -Append
					Write-Output "WINS Servers :  $WINSPrimaryServer $WINSSecondaryServer" | Out-File -FilePath log.txt -Append
					Write-Output "`t" | Out-File -FilePath log.txt -Append
					Write-Output "`t" | Out-File -FilePath log.txt -Append

					Write-host "===================="
					Write-host $now
					Write-host "===================="
					write-host "Machine Checked :  $strSrvr"
					Write-host "Response Time :  $RoundTrip ms"
					write-host "DNS Name :  $DNSHostName"
					write-host "DNS Domain :  $DNSDomain"
					write-host "Description :  $Description"
					write-host "MAC Address :  $MACAddress"
					Write-host "DHCP Enabled :  $DHCPEnabled"
					write-host "IPAddress :  $IPAddress"
					write-host "IPEnabled :  $IPEnabled"
					write-host "DNS Servers :  $DNSServerSearchOrder"
					write-host "WINS Servers :  $WINSPrimaryServer $WINSSecondaryServer"
					Write-Host "`t"
					Write-Host "`t"
				}
			}
			else {
				[string]$Address = $Reply.Address
				$now1 = Get-Date -uFormat %x
				$now2 = Get-Date -Format T
				$now = $now1 + " " + $now2 + ":"
				Write-Output "====================" | Out-File -FilePath log.txt -Append
				Write-Output $now | Out-File -FilePath log.txt -Append
				Write-Output "====================" | Out-File -FilePath log.txt -Append
				Write-Output "$Address is not a Windows based computer" | Out-File -FilePath log.txt -Append
				Write-Output "`t" | Out-File -FilePath log.txt -Append
				Write-Output "`t" | Out-File -FilePath log.txt -Append
				Write-host "===================="
				Write-host $now
				Write-host "===================="
				write-host "$strSrvr is not a Windows based computer"
				Write-Host "`t"
				Write-Host "`t"
			}
		}
		else {
			$now1 = Get-Date -uFormat %x
			$now2 = Get-Date -Format T
			$now = $now1 + " " + $now2 + ":"
			Write-Output "====================" | Out-File -FilePath log.txt -Append
			Write-Output $now | Out-File -FilePath log.txt -Append
			Write-Output "====================" | Out-File -FilePath log.txt -Append
			Write-Output "$strSrvr did not respond" | Out-File -FilePath log.txt -Append
			Write-Output "`t" | Out-File -FilePath log.txt -Append
			Write-Output "`t" | Out-File -FilePath log.txt -Append
			Write-host "===================="
			Write-host $now
			Write-host "===================="
			Write-Host "$strSrvr did not respond"
			Write-Host "`t"
			Write-Host "`t"
		}
	}
}