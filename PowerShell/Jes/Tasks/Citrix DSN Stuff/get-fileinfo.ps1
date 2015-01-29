$erroractionpreference = "SilentlyContinue" 

$list = Get-Content $args[0]
$location = $args[1]
$line = $args[2]
$output = "Get-FileInfo.csv"
$count = 0

$table = New-Object system.Data.DataTable "table"
$col1 = New-Object system.Data.DataColumn Server,([string])
$col2 = New-Object system.Data.DataColumn Metaframe,([string])
$table.columns.add($col1)
$table.columns.add($col2)

foreach ($item in $list) {
	$count += 1
}
Write-Host $Count "servers to query"

foreach ($item in $list) {
	$reported +=1
	$openfile = "\\" + $item + "\" + $location -replace ":","$"
	$text = Get-Content $openfile | Select-String -list $line

	$row = $table.NewRow()
	$row.Server = $item
	$row.Metaframe = $text -replace "SERVER=",""
	$table.Rows.Add($row)
	
	if (($reported % 10) -eq 0 -or $reported -eq $count -and $reported -ne 0) {
		Write-Host " " $reported "of" $count "MetaFrame servers reported"
	}
}

#$table | sort-object Server

$out = $table | Sort-Object Server | Export-Csv $output -NoTypeInformation