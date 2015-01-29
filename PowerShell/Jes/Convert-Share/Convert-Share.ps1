$strCurrDir =  [System.IO.Directory]::GetCurrentDirectory()
$outFile = $strCurrDir +"\out.csv"

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$objGetFile = New-Object Windows.Forms.OpenFileDialog
$objGetFile.Title = "Open - Share Folder Conversion List"
$objGetFile.Filter = "Text Files(*.txt)|*.txt|All Files(*.*)|*.*"
$objGetFile.ShowDialog()
$objShares = get-content $objGetFile.FileName

# Setup the Datatable Structure
$table = New-Object system.Data.DataTable “Share Setup”
$col1 = New-Object system.Data.DataColumn Share,([string])
$col2 = New-Object system.Data.DataColumn Group,([string])
$col3 = New-Object system.Data.DataColumn Access,([string])

$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)

foreach ($strShares in $objShares)
{
	$strGroup = $strShares.ToLower() -replace "\\","~" -replace " ","_" -replace "~~","" -replace "data",""
	$strGroupA = $strGroup + "~a"
	$strGroupM = $strGroup + "~m"
			
	#a
	$row = $table.NewRow()
	$row.Share = $strShares
	$row.Group = $strGroupA
	$row.Access = "Approver"
	$table.Rows.Add($row)
	
	#m
	$row = $table.NewRow()
	$row.Share = $strShares
	$row.Group = $strGroupM
	$row.Access = "Modify"
	$table.Rows.Add($row)

	if (-not ($strShares -like "*public"))
	{
		$strGroupR = $strGroup + "~r"
	}
	
	else
	{
		$strGroupR = "CORP\Cargill Authenticated Users"
	}		
	
	#r
	$row = $table.NewRow()
	$row.Share = $strShares
	$row.Group = $strGroupR
	$row.Access = "Read-Only"
	$table.Rows.Add($row)
}
$table | Select-Object -Property Share, Group, Access | Export-Csv -noTypeInformation -Force -Path $outFile
$filter = (Get-Content $outFile) -replace "`"",""
Set-Content $outFile $filter

$excel = new-object -comobject Excel.Application
$excel.visible = $True
$excel.Workbooks.Open($outFile)