$list = New-Object System.Collections.ArrayList
$orig = Get-Content list.txt

foreach ($line in $orig) {
	$line = $line -replace "`t",";"
	$split = $line.Split(',;')
	foreach ($item in $split) {
		$add = $list.Add($item.ToLower())
	}
}

$unique = $list | Sort-Object | Get-Unique | where {$_ -ne ""}

$unique | Out-File sorted.txt