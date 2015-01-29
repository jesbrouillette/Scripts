Set-Alias se Set-ExecutionPolicy

function GetRegistryValues ($key) {
	(Get-Item $key).GetValueNames()
}


function GetRegistryValue ($key, $value) {
	(Get-ItemProperty $key $value).$value
}


function ConvertSID ($sid) {
	$secID = New-Object System.Security.Principal.SecurityIdentifier $sid
	($secID.Translate([System.Security.Principal.NTAccount])).Value
}

function raCORP ($app) {
	runas /user:corp\admin_jebrouil $app
}

function raMEAT ($app) {
	runas /user:meat\jebrouil $app
}

function EditProf {
	notepad $profile
}

function LoadProf {
	.$profile
}

function GenPwd ($CharLen) {
	if (!$CharLen) { $CharLen = 10 }
 	$alphaLow = "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
 	$alphaCap = "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"
 	$numb = "1","2","3","4","5","6","7","8","9"
 	$special = "`~","`!","`@","`#","`$","`%","`^","`&","`*","'(","`)","`_","`+","`|","'{","`}","`:","`"","`<","`>","`?","``","`-","`=","`\","`[","`]","`;","`'","`,","`.","`/"
 	$aLLen = $alphaLow.Length
 	$aCLen = $alphaCap.Length
 	$nLen = $numb.Length 
 	$sLen = $special.Length
 	$rand = New-Object System.Random
 	$generate = (0..($CharLen - 1)) | % {
		$rand.Next(0,4)
		Start-Sleep -m 1
	}
	$generated = [regex]::split($generate," ")
	foreach ($number in $generated) {
	if ($number -eq 0) { $charNumb = $rand.Next(0,([Int32]$aLLen - 1)) ; $char += $alphaLow[$charNumb] ; Start-Sleep -m 1 }
		elseif ($number -eq 1) { $charNumb = $rand.Next(0,([Int32]$aCLen - 1)) ; $char += $alphaCap[$charNumb] ; Start-Sleep -m 1 }
		elseif ($number -eq 2) { $charNumb = $rand.Next(0,([Int32]$nLen - 1)) ; $char += $numb[$charNumb] ; Start-Sleep -m 1 }
		elseif ($number -eq 3) { $charNumb = $rand.Next(0,([Int32]$sLen - 1)) ; $char += $special[$charNumb] ; Start-Sleep -m 1 }
	}
	return $char
}

function getshare {
	param (
		[string]$name,  #Machine to gather shares from
		[string]$exclude, #Text to filter out (*$ to filter out admin shares)
		[string]$include, #Text to search for
		[string]$csv      #Output to csv
	)
	if ($exclude -and $include)  { $list = GWMI win32_share -computer $name | ? {($_.name -notlike $exclude) -and ($_.name -like $include)} }
	elseif ($exclude) { $list = GWMI win32_share -computer $name | ? {$_.name -notlike $exclude} }
	elseif ($include) { $list = GWMI win32_share -computer $name | ? {$_.name -like $include} }
	else { $list = GWMI win32_share -computer $name }
	if ($csv) { $list | Export-Csv $csv -NoTypeInformation ; Import-Csv $csv | select Name,Path,Description | fl}
	else { $list | fl }
}

function psping {
	param (
		[string]$name, #Machine to ping
		[string]$i,    #Time To Live
		[string]$j,    #Loose source route along host-list
		[string]$k,    #Strict source route along host-list
		[string]$l,    #Send buffer size
		[string]$r,    #Record route for count hops
		[string]$n,    #Number of echo requests to send
		[string]$s,    #Timestamp for count hops
		[string]$v,    #Type Of Service
		[string]$w,    #Timeout in millieseonds to wait for each reply
		[switch]$a,    #Resolve address to hostnames
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
			$loss = [Math]::Round((($count / $received) - 1)*100,2)
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
}

function shut-down {
	shutdown -s -t 00
	Write-Host "Shutting down"
}

function Query-DB{

	# SQL Database - Query-DB.ps1 -cmd "SELECT TOP 10 * FROM Orders"
	# Access Database - Query-DB (Resolve-Path access_test.mdb) -cmd "SELECT * FROM Users"
	# Excel file - Query-DB (Resolve-Path xls_test.xls) -cmd 'SELECT * FROM [Sheet1$]'
	
	param(
		[string] $ds = $(Read-Host "Please specify a data source."),
		[string] $db = $(Read-Host "Please specify a database."),      
		[string] $cmd = $(Read-Host "Please specify a query."),
		[switch] $winauth
		
	  )
	
	
	
	if(!$winauth)
	{
		[System.Management.Automation.PsCredential] $credential = $(Get-Credential)	
		$plainCred = $credential.GetNetworkCredential()
		$authentication = 
			("uid={0};pwd={1};" -f $plainCred.Username,$plainCred.Password)
	}
	else {		
		$authentication = "Integrated Security=SSPI;"		
	}

	$connectionString = "Provider=sqloledb; " +
	                    "Data Source=$ds; " +
	                    "Initial Catalog=$db; " +
	                    "$authentication; "

	if($ds -match '\.xls$|\.mdb$')
	{
	    $connectionString = "Provider=Microsoft.Jet.OLEDB.4.0; Data Source=$ds; "
	
	    if($ds -match '\.xls$')
	    {
	        $connectionString += 'Extended Properties="Excel 8.0;"; '
	
	        if($cmd -notmatch '\[.+\$\]')
	        {
	            $error = 'Sheet names should be surrounded by square brackets, and ' +
	                       'have a dollar sign at the end: [Sheet1$]'
	            Write-Error $error
	            return
	        }
	    }
	}
	
	$connection = New-Object System.Data.OleDb.OleDbConnection $connectionString
	$command = New-Object System.Data.OleDb.OleDbCommand $cmd,$connection
	$connection.Open()
	
	$adapter = New-Object System.Data.OleDb.OleDbDataAdapter $command
	$dataset = New-Object System.Data.DataSet
	[void] $adapter.Fill($dataSet)
	$connection.Close()
	
	$dataSet.Tables | Select-Object -Expand Rows
}

function Prompt {
	$hostver = $host.Version
	$build = $hostver.build
	$revis = $hostver.revision
	Write-Host -NoNewLine "$(Get-Location)> "
	$host.UI.RawUI.WindowTitle = "PowerShell v$hostver Build $build Rev $revis :: $env:Userdomain\$env:Username :: $(Get-Location)"
	$host.privatedata.ErrorForegroundColor = "Magenta"
	$host.privatedata.ErrorBackgroundColor = "DarkBlue"
	$host.privatedata.WarningBackgroundColor = "DarkBlue"
	$host.privatedata.DebugBackgroundColor = "DarkBlue"
	$host.privatedata.VerboseBackgroundColor = "DarkBlue"
	"`b"
}

cls
set-location C:\ittools\Scripting\PowerShell
"Powershell now started"
"Logged in to the " + $env:Userdomain + " domain as " + $env:Username
write-host