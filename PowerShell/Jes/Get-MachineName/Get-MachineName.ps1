param (
	[string] $file, #fiie to import other than list.txt
	[string] $server, #queries a single server
	[switch] $console, #outputs to console
	[switch] $exc, #imports to Excel instead of a csv file
	[switch] $os #attempts to get os version
)

###############################################################################
# Gather the machine name for a given IP                                      #
#                                                                             #
# Created By: Jes Brouillette                                                 #
# Creation Date: 08/11/09                                                     #
# Usage: .\Get-MachineName.ps1 <txt file of ip's>                             #
###############################################################################

$erroractionpreference = "Continue"

function ToExcel ($queried,$ipAddress,$fQDN,$err) {
	$worksheet.Cells.Item($col, $row) = $queried
	if ($err) { $worksheet.Cells.Item($col, $row).Font.ColorIndex = 3 }
	$row = $row + 1
	$worksheet.Cells.Item($col, $row) = $ipAddress
	if ($err) { $worksheet.Cells.Item($col, $row).Font.ColorIndex = 3 }
	$row = $row + 1
	$worksheet.Cells.Item($col, $row) = $fQDN
	if ($err) { $worksheet.Cells.Item($col, $row).Font.ColorIndex = 3 }
	$col = $col + 1
}

function ToCSV ($queried,$ipAddress,$fQDN) {
	$tRow = $table.NewRow()
	$tRow.QUERIED = $queried
	$tRow.IP = $ipAddress
	$tRow.FQDN = $fQDN
	$table.Rows.Add($tRow)
}

if (!$exc) { $outfile = "Get-MachineName.csv" }

if ($exc) {
	$excel = New-Object -comobject Excel.Application
	$excel.visible = $True 
	
	$workbook = $excel.Workbooks.Add()
	$worksheet = $workbook.Worksheets.Item(1)
	
	$col = 1
	$row = 1

	$worksheet.Cells.Item($col, $row) = "Queried"
	$row = $row + 1
	$worksheet.Cells.Item($col, $row) = "IP Address"
	$row = $row + 1
	$worksheet.Cells.Item($col, $row) = "FQDN"
	$col = $col + 1
	$row = 1
} else {
	$table = New-Object system.Data.DataTable ""
	$col1 = New-Object system.Data.DataColumn QUERIED,([string])
	$col2 = New-Object system.Data.DataColumn IP,([string])
	$col3 = New-Object system.Data.DataColumn FQDN,([string])
	$table.Columns.Add($col1)
	$table.Columns.Add($col2)
	$table.Columns.Add($col3)
}
if ($file -ne "" ) { $list = Get-Content $file | Sort -Unique}
elseif ($server) { $list = $server.Split(" ") | Sort -Unique }
else { $list = Get-Content list.txt }
if ($list.Count) { $total = $list.Count }
else { $total = "1" }

$timeout = [int32]5000

Write-Host "Gathering information for:"
$count = 0

foreach($IP in $List) {
	$count +=1
	Write-Host "$item  ($count of $total)"-NoNewline
	
	$ping = New-Object System.Net.NetworkInformation.Ping
	$Reply = $ping.send($IP,$timeout)

	if ($Reply.status –eq "Success") {
		$fQDN = [System.Net.DNS]::GetHostEntry($Reply.Address).HostName
		if ($exc) { ToExcel $IP $Reply.Address.IPAddressToString $fQDN ; $col = $col + 1 }
		else { ToCSV $IP $Reply.Address $fQDN }
	} else {
		if ($exc) { ToExcel $IP "unreachable" "unknown" "1" ; $col = $col + 1 }
		else { ToCSV $IP "unreachable" "unknown" }
	}
	$Reply = $null
}

if ($exc) {
	$usedrange = $worksheet.UsedRange
	$filter = $usedrange.EntireColumn.AutoFilter()
	$fit = $usedrange.EntireColumn.AutoFit()
} else {
	if ($console) {
		if ($table.Rows.Count -eq 1) { $table | Select QUERIED,IP,FQDN | Format-List }
		else { $table | Select-Object QUERIED,IP,FQDN }
	}
	$table | Select-Object QUERIED,IP,FQDN | Export-Csv -NoTypeInformation $outfile
}