$list = Get-Content list.txt 
$data = @() 

foreach ($item in $list) { 
	$row = "" | select Folder,Size
	gci $list.folder -recurse | % {$size += $_.length / 1mb} 
	$row.Directory = $list.folder
	$row.Size = $size 
	rv size 
	$data += $row 
}

$data | Export-Csv -NoTypeInformation "list.csv"