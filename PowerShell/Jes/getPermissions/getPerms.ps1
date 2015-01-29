$erroractionpreference = "SilentlyContinue"

$shares = Get-Content $args[0]

ri "c:\temp.csv"
ri "c:\temp1.csv"
ri "c:\temp2.csv"
ri "c:\temp.xlsx"
ri "c:\perms.csv"

$excelApp = New-Object -comobject Excel.Application
$excelApp.visible = $True 

$excelWBook = $excelApp.Workbooks.Add()
$excelWSheet = $excelWBook.Worksheets.Item(1)

$excelWSheet.Cells.Item(1,1) = "Path"
$excelWSheet.Cells.Item(1,2) = "Group"
$excelWSheet.Cells.Item(1,3) = "Permissions"


$intRow = 2

foreach ($folder in $shares)
{
	get-acl $folder | select-object accesstostring | format-custom | out-file -encoding default export.tmp
	$strReplace = @("class PSCustomObject","{","AccessToString \=","BUILTIN\\Administrators Allow  FullControl","Synchronize","NT AUTHORITY\\SYSTEM Allow  FullControl","}"," {2,}")
	foreach ($replace in $strReplace)
	{
		$new = (gc export.tmp | where {$_ -ne ""}) -replace $replace, ""
		Set-Content export.tmp $new
	}
	$newPerms = gc export.tmp | where {$_ -ne ""}
	foreach ($newPerm in $newPerms)
	{
		$excelWSheet.Cells.Item($intRow, 1) = $folder
		$excelWSheet.Cells.Item($intRow, 2) = $newPerm
		$intRow = $intRow + 1
	}
}


$excelSaveAs = $excelWBook.SaveAs("c:\temp.csv",6)
$excelSaveAs = $excelWBook.SaveAs("c:\temp.xlsx")
$excelClose = $excelWBook.Close("false")

$csvFormat = (gc C:\temp.csv) -replace " Allow","`","
Set-Content C:\temp1.csv $csvFormat

$csvFormat = (gc C:\temp1.csv) -replace "ReadAndExecute","Read"
Set-Content C:\temp2.csv $csvFormat

$csvFormat = (gc C:\temp2.csv) -replace ", `",",""
Set-Content c:\perms.csv $csvFormat

$excelWBook1 = $excelApp.Workbooks.Open("c:\perms.csv")
$excelWSheet1 = $excelWBook1.Worksheets.Item(1)

$excelInput1 = $excelWSheet1.Range("A1:C1")
$excelInput1.Interior.ColorIndex = 19
$excelInput1.Font.ColorIndex = 11
$excelInput1.Font.Bold = $True

$e1 = $excelInput1.EntireColumn.AutoFilter()
$f1 = $excelInput1.EntireColumn.AutoFit()

ri "export.tmp"
ri "c:\temp.csv"
ri "c:\temp1.csv"
ri "c:\temp2.csv"
ri "c:\temp.xlsx"