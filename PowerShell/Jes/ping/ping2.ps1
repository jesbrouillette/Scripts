#$erroractionpreference = "SilentlyContinue"
$excelApp = New-Object -comobject Excel.Application
$excelApp.visible = $True 

$excelWBook = $excelApp.Workbooks.Add()
$excelWSheet = $excelWBook.Worksheets.Item(1)

$excelWSheet.Cells.Item(1,1) = "IP/Name Checked"
$excelWSheet.Cells.Item(1,2) = "Ping Status"
$excelWSheet.Cells.Item(1,3) = "IP Replied"
$excelWSheet.Cells.Item(1,4) = "DNS HostName"

$excelInput = $excelWSheet.UsedRange
$excelInput.Interior.ColorIndex = 19
$excelInput.Font.ColorIndex = 11
$excelInput.Font.Bold = $True

$intRow = 2

$colComputers = get-content $args[0]
foreach ($strComputer in $colComputers)
{
	$excelWSheet.Cells.Item($intRow, 1) = $strComputer.ToUpper()
	
	# This is the key part
	
	$timeout=120;
	$ping = new-object System.Net.NetworkInformation.Ping
	$reply = $ping.Send($strComputer,$timeout)

	if ($Reply.status –eq "Success") 
	{
		$ip = ($ping.send($strComputer).address).ipaddresstostring
		$excelWSheet.Cells.Item($intRow, 2) = "Success"
		$excelWSheet.Cells.Item($intRow, 2).Font.ColorIndex = 10
		$excelWSheet.Cells.Item($intRow, 3) = $ip
		$excelWSheet.Cells.Item($intRow, 3).Font.ColorIndex = 10
		$excelWSheet.Cells.Item($intRow, 4) = ([System.Net.Dns]::GetHostbyAddress($ip)).HostName
		$excelWSheet.Cells.Item($intRow, 4).Font.ColorIndex = 10
	}
	else 
	{
		$excelWSheet.Cells.Item($intRow, 2) = "Failed: " + $Reply.status
		$excelWSheet.Cells.Item($intRow, 2).Font.ColorIndex = 3
		$excelWSheet.Cells.Item($intRow, 3) = "Unknown"
		$excelWSheet.Cells.Item($intRow, 3).Font.ColorIndex = 3
		$excelWSheet.Cells.Item($intRow, 4) = "Unknown"
		$excelWSheet.Cells.Item($intRow, 4).Font.ColorIndex = 3
	}
	
	$Reply = ""
	$Address = ""
	$intRow = $intRow + 1
}

$filter = $excelInput.EntireColumn.AutoFilter()
$fit = $excelInput.EntireColumn.AutoFit()

ri address.tmp