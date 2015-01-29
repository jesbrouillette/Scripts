
# ================= #
# Start Change-Path #
# ================= #

$list = New-Object System.Collections.ArrayList
$orig = $env:path
$orig | Out-File orig.txt

foreach ($line in $orig) {
	$line = $line -replace "`t",";"
	$split = $line.Split(',;')
	foreach ($item in $split) {
		$add = $list.Add($item.ToLower())
	}
}

$unique = $list | Sort-Object | Get-Unique | where {$_ -ne ""}

foreach ($line in $unique) {
	if ($line -notmatch "oracle") {
		$final += $line + ";" -replace ";;",";"
	}
}

$env:Path = $final
$final | Out-File sorted.txt

# =============== #
# End Change-Path #
# =============== #
