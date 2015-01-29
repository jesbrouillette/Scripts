param (
	[switch] $inherit, #inherits credentials
	[switch] $continuous #continuous monitoring
)

if ($args[0] -like "*.txt") {
	$file = $true
	$list = Get-Content $args[0]
}
else {
	$list = $args[0]
}
$service = $args[1]

if (!$inherit) {
	$Cred = Get-Credential
}

function check-services ($fServer,$time) {
	$reply = $ping.Send($fServer,$timeout)

	if ($reply.status –eq "Success") {
		if (!$inherit) {
			$ServiceCheck = Get-WmiObject -ComputerName $fServer -Credential $Cred -class win32_service -filter "name='$service'"
		} else {
			$ServiceCheck = Get-WmiObject -ComputerName $fServer -class win32_service -filter "name='$service'"
		}
		if ($error) {
			$state = "Unknown"
			$status = "Unknown"
			$start_mode = "Unknown"
		}
		else {
			$service = [string]$Servicecheck.name
			$state = [string]$Servicecheck.state
			$status = [string]$Servicecheck.status
			$start_mode = [string]$Servicecheck.startmode
		}
	}
	else {
		$status = "Not Available"
	}
	$error.clear()
	if ($status -ne $statusold) {
		$row = $statuslog.newrow()
		$row.server = $fServer
		$row.service = $service
		$row.state = $state
		$row.status = $status
		$row.start_mode = $start_mode
		if ($time) { $row.time = (Get-Date -Format "h:mm:ss tt") }
		$addrow = $statuslog.rows.add($row)
		clear-host
		$statuslog | Format-Table
	}
	Set-Variable -Scope Script -Name status_last -Value $status
} # end function check-services
	

$StatusLog = New-Object system.Data.DataTable "StatusLog"
$col1 = New-Object system.Data.DataColumn Server,([string])
$col2 = New-Object system.Data.DataColumn Service,([string])
$col3 = New-Object system.Data.DataColumn State,([string])
$col4 = New-Object system.Data.DataColumn Status,([string])
$col5 = New-Object system.Data.DataColumn Start_Mode,([string])
if ($continuous -or !$files) { $col6 = New-Object system.Data.DataColumn Time,([string]) }

$addcolumn = $StatusLog.columns.add($col1)
$addcolumn = $StatusLog.columns.add($col2)
$addcolumn = $StatusLog.columns.add($col3)
$addcolumn = $StatusLog.columns.add($col4)
$addcolumn = $StatusLog.columns.add($col5)
if ($continuous -or !$files) { $addcolumn = $StatusLog.columns.add($col6) }

$ping = new-object System.Net.NetworkInformation.Ping
$timeout=120;

$error.clear()

if ($continuous -and !$file) {
	do {
		$error.clear()
		$now = $true
		check-services $list $now
		do {
			$p += 1
			Write-Host "`b\" -NoNewline
			Start-Sleep -Milliseconds 250 
			Write-Host "`b|" -NoNewline
			Start-Sleep -Milliseconds 250
			Write-Host "`b/" -NoNewline
			Start-Sleep -Milliseconds 250
			Write-Host "`b-" -NoNewline
			Start-Sleep -Milliseconds 250
		} until ($p -ge 10)
		$p = 0
		Write-Host ""
	} until (!$continuous)
} elseif (!$file) {
	$error.clear()
	$now = $true
	check-services $list $now
} else {
	foreach ($server in $list) {
		$error.clear()
		check-services $server $now
	}
}

$StatusLog | Select-Object Server,Service,State,Status,Start_Mode,Time | Export-Csv StatusLog.csv -NoTypeInformation