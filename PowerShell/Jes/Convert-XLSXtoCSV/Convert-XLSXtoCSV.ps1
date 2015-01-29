$filepath = "p:\projects\DCN\MG4_Data\MG_Data.xlsm"
Write-Host "starting excel and opening the file"
$excel = new-object -comobject excel.application
$workbook = $excel.workbooks.open($filepath)
$worksheet = $workbook.worksheets.item(1)
Write-Host "running macro"
$excel.Run("Refresh_Data")
$workbook.save()
$workbook.close()
$excel.quit()
Write-Host "importing data from excel"
$connString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=`"$filepath`";Extended Properties=`"Excel 12.0 Xml;HDR=YES`";"
$qry = 'select * from [MG_Data$]'
 
$conn = new-object System.Data.OleDb.OleDbConnection($connString)
$conn.open()
$cmd = new-object System.Data.OleDb.OleDbCommand($qry,$conn) 
$da = new-object System.Data.OleDb.OleDbDataAdapter($cmd) 
$dt = new-object System.Data.dataTable 
[void]$da.fill($dt)
$conn.close()


$accessApp = New-Object -com access.application

$accessApp.Application.OpenCurrentDatabase("P:\Projects\DCN\MG4_Data\MG_Data.accdb")

$accessApp.Application.DoCmd.RunMacro("gr8eqlzero")

$accessApp.Application.CloseCurrentDatabase()