# $files = Get-ChildItem -Path "C:\ittools\Scripting\PowerShell\Change-Format" -Name -Include "*.csv"
$files = "1.csv"

$table = New-Object system.Data.DataTable "Group DataTable" # Setup the Datatable Structure
$col1 = New-Object system.Data.DataColumn Share,([string])
$col2 = New-Object system.Data.DataColumn Approve,([string])
$col3 = New-Object system.Data.DataColumn Modify,([string])
$col4 = New-Object system.Data.DataColumn Read,([string])
$table.columns.add($col1)
$table.columns.add($col2)
$table.columns.add($col3)
$table.columns.add($col4)

foreach ($file in $files) {
	# $answer = Read-Host "Do you want to parse" $file
	$answer = "yes"
	if ($answer -like "yes") {
		$contents = Import-Csv $file
		foreach ($content in $contents) {
			$replaces = [string]$content
			foreach ($replace in $replaces) {
				# $replace
				$replacing = [string]$replace
				# $replacing
				$replaced = [string]$replace -replace ".read=x","=read" -replace ".approve=x","=approve" -replace ".modify=x","=modify" -replace ".read=;","=;" -replace ".approve=;","=;" -replace ".modify=;","=;"
				$replaced | Out-File test1.txt -Append
				$new = Get-Content test1.txt
			}
		}
	}elseif ($answer -like "no") {
		Write-Host "Skipped" $file
	}
	$answer = "no"
}