param (
	[string]$file
)

$list = Get-Content $file
$new = @()
foreach ($line in $list) {
	if ($prev) {
		if ($line -match " : ") {
			$line = $line.Replace(" : ",",`"")
			$line = $line.TrimEnd(",")
			$line += "`""
		}
		if ($line[0] -eq ",") {
			$prev += $line
			$new += $prev
		}
		elseif ($prev[0] -ne ",") {
			$new += $prev
		}
		$prev = $line
	}
	else { $prev = $line }
}
$new += $list[$list.Count-1]
rv prev
"TimeStamp,Error,Message,Details" | Out-File "test.csv" -Encoding ASCII
$new | Out-File "test.csv" -Encoding ASCII -Append
$import = Import-Csv "test.csv"
$import