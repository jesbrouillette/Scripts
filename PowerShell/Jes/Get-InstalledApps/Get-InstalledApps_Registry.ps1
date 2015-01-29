#registry hive constants
$HKLM=2147483650
$HKCU=2147483649
$HKCR=2147483648
$HKEY_USERS=2147483651 

$objExcel = New-Object -comobject Excel.Application
$objExcel.visible = $True

$intSheetNumb = 1
$objWorkbooks = $objExcel.Workbooks.Add()

$cred = Get-Credential
$strRegKey = "Software\Microsoft\Windows\CurrentVersion\Uninstall"

function GetInfo($strSrvr,$intSheet) {

	$intRow = 1
	$strSheet = "Sheet" + $intSheet
	
	$objWorksheets = $objWorkbooks.Worksheets | where {$_.name -eq $strSheet}
	$objWorksheets.Name = $strSrvr
		
	$objWorksheets.Cells.Item($intRow,1) = "Name"
	$objWorksheets.Cells.Item($intRow,2) = "Version"
	$objWorksheets.Cells.Item($intRow,3) = "Publisher"
	
	$objUsedRange = $objWorksheets.UsedRange
	$objUsedRange.Interior.ColorIndex = 19
	$objUsedRange.Font.ColorIndex = 11
	$objUsedRange.Font.Bold = $True
	
	$intRow = $intRow + 1

	$objReg = Get-WmiObject -Namespace Root\Default -List -ComputerName $strSrvr -Credential $cred | Where-Object {$_.Name -eq "StdRegProv"} 
	$regKeys = $objReg.enumKey($HKLM, $strRegKey)
	
	$regKeys | foreach {Write-output $_.sNames} | foreach {
	
		$strInstKeys = $strRegKey + "\" + $_
	
		$strDisplayName = $objReg.GetStringValue($HKLM, $strInstKeys, "DisplayName").sValue
		if ($strDisplayName -ne $null -and $strDisplayName -notlike "Security Update for*" -and $strDisplayName -notlike "Update for Windows*" -and $strDisplayName -notlike "*Hotfix*") {
			$strDisplayVersion = $objReg.GetStringValue($HKLM, $strInstKeys, "DisplayVersion").sValue
			$strPublisher = $objReg.GetStringValue($HKLM, $strInstKeys, "Publisher").sValue
			
			$objWorksheets.Cells.Item($intRow,1) = $strDisplayName
			$objWorksheets.Cells.Item($intRow,2) = $strDisplayVersion
			$objWorksheets.Cells.Item($intRow,3) = $strPublisher
			$intRow = $intRow + 1
		}
	}
	$actFit = $objUsedRange.EntireColumn.AutoFit()
	$actFit = $objUsedRange.EntireColumn.AutoFilter()
	$objAddWorkSheet = ($objWorkbooks.sheets).add()
}

if ($args[0] -eq "multi") {
    $InFile = Get-Content $args[1].ToString()
	$count = 0
	$first = $InFile[0].ToString
	foreach ($strSrvrName in $InFile) {
		$count += 1
	}
	foreach ($strSrvrName in $InFile) {
		Write-Host "Getting info for" $strSrvrName "::" $intSheetNumb "of" $count
		GetInfo $strSrvrName $intSheetNumb
		$intSheetNumb = $intSheetNumb + 1
	}
}

if ($args[0] -eq "single") {
	Write-Host "Getting info for" $args[1].ToString()
	$first = $args[1].ToString()
	GetInfo $strSrvrName $intSheetNumb
}

#$objWorksheets = $objWorkbooks.Worksheets | where {$_.name -eq $first}
$objWorkbooks.workSheets.Count
$objDelWorksheet = $objWorkbooks.workSheets.item($objWorkbooks.workSheets.Count).delete()
$objWorkbooks.workSheets.Count
$objDelWorksheet = $objWorkbooks.workSheets.item($objWorkbooks.workSheets.Count).delete()