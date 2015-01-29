$list = Get-Content $args[0]
$endfiles = $args[1]
$lines = 0
$line_count = 0
$line_count1 = 0
$newcount = 0
$newlist = New-Object System.Collections.ArrayList

foreach ($line in $list) {
	$lines += 1
}

foreach ($line in $list) {
	$line_count += 1
	$line_count1 += 1
	$add = $newlist.Add($line)

	if ($line_count -eq $endfiles -or $line_count1 -eq $lines) {
		$newcount += 1
		$newdir = "RUN" + $newcount
		$create_directory = New-Item $newdir -type directory
		$newfile = "RUN" + $newcount + "\output" + $newcount + ".txt"
		$create_new_file = $newlist | Out-File $newfile -Encoding ASCII
		$clear = $newlist.Clear()
		$line_count = 0
	}
}