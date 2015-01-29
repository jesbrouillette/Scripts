param (
	$list #csv with source and destination
)

$ErrorActionPreference = "Continue"
$list = Import-Csv $list

foreach ($item in $list) (
	if ($Recurse) { $copy = Copy-Item $item.Source $item.Destination -Recurse }
	else { $copy = Copy-Item $item.Source $item.Destination }
	for ($a=1; $a -lt 100; $a++) {
		Write-Progress -Activity "Copying..." -SecondsRemaining $a -Status "% Complete:" -percentComplete $a
	}
}