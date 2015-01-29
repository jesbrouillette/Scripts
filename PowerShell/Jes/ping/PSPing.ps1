function psping {
	param (
		[string]$name, #Machine to ping
		[string]$i,    #Time To Live
		#[string]$j,    #Loose source route along host-list
		#[string]$k,    #Strict source route along host-list
		[string]$l,    #Send buffer size
		#[string]$r,    #Record route for count hops
		[string]$n,    #Number of echo requests to send
		#[string]$s,    #Timestamp for count hops
		#[string]$v,    #Type Of Service
		[string]$w,    #Timeout in millieseonds to wait for each reply
		#[switch]$a,    #Resolve address to hostname
		[switch]$f,    #send Don't Fragment flag in packet
		[switch]$t     #Ping the specified host until stopped
	)
	
	$ErrPref = $ErrorActionPreference
	$erroractionpreference = "SilentlyContinue"
	
	if ($i) { [int]$setTTL = $i } else { [int]$setTTL = 125 }
	if ($l) { [int]$setBufferSize = $l } else { [int]$setBufferSize = 32 }
	if ($n) { $setPingAttempts = $n } else { $setPingAttempts = 4 }
	if ($t) { $setPingAttempts = 0 }
	if ($w) { [int]$setTimeout = $w } else {[int]$setTimeout = 120 }
	if ($f) { [switch]$setDontFragment = $true } else { [switch]$setDontFragment = $false }
		
	$setOptions = new-object System.Net.NetworkInformation.PingOptions 
	$setOptions.TTL = $setTTL 
	$setOptions.DontFragment = $setDontFragment 
	$setBuffer=([system.text.encoding]::ASCII).getbytes("a"*$setBufferSize)

	$ping = New-Object System.Net.NetworkInformation.Ping
	$reply = $ping.send($name)
	Write-Host ""
	if (!$reply) {
		$msg = "Ping request could not find host " + $name + ". Please check the name and try again."
		$msg
	} elseif ($reply.Status -eq "Success" -or $reply.Status -eq "TimedOut") {
		$fqdn = [system.net.dns]::GetHostEntry($name).HostName
		if ($reply.Address.IPAddressToString -ne $null) { $msg = "Pinging " + $fqdn + " `[" + $reply.Address.IPAddressToString + "`] with " + $l + " bytes of data`:`n" }
		else { $msg = "Pinging " + $fqdn + " with 32 bytes of data`:`n" }
		Write-Host $msg
		$count = 0
		$roundTripMin = 126
		$roundTripMax = 0
		$roundTripCount = 0
		$roundTripAvg = 0
		$received = 0
		do {
			Start-Sleep -seconds 1
			$count += 1
			$reply = $ping.Send($name,$setTimeOut,$setBuffer,$setOptions)
			$ip = $reply.Address.IpAddressToString
			if ($reply.Status -eq "Success") {
				$buffer = $reply.Buffer.Count
				$roundTrip = $reply.RoundtripTime
				$ttl =$reply.Options.Ttl
				$received += 1
				if ($roundTrip -lt $roundTripMin) { $roundTripMin = $roundTrip }
				if ($roundTrip -gt $roundTripMax) { $roundTripMax = $roundTrip }
				$roundTripCount += $roundTrip
				$msg = "Reply from " + $ip + "`: bytes=" + $buffer + " time=" + $roundTrip + " ttl=" + $ttl
			} elseif ($reply.Status -eq "TtlExpired") {
				$msg = "Reply from " + $ip + "`: TTL expired in transit."
			} elseif ($reply.Status -eq "TimedOut") {
				$msg = "Request timed out."
			}
			Write-Host $msg
		} until ( $count -eq $setPingAttempts )
		if ($received -gt 0) {
			$loss = (($count / $received) - 1) * 100
			$roundTripAvg = [Math]::Round(($roundTripCount/$count),2)
		} else { 
			$loss = 
			$roundTripAvg = 0
		}
		$msg = "
Ping statistics for " + $reply.Address.IpAddressToString + ":
	Packets: Sent = " + $count + ", Received = " + $received + ", Loss = " + ($count - $received) + " (" + $loss + "% loss),
Approximate round trip times in milli-seconds:
	Minimum = " + $roundTripMin + "ms, Maximum = " + $roundTripMax + "ms, Average = " + $roundTripAvg + "ms"
		
		Write-Host $msg
	} else {
		$reply
	}
$ErrorActionPreference = $ErrPref
rv reply
rv ErrPref
} psping xlwicha11m