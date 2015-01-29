$list = Get-Content "list.txt"
$search = "`*" + $args[0] + "`*"
foreach ($item in $list) { 
	$path = "\\" + $item + "\c`$\source\library\package logs\"
	$item
	$files = Get-ChildItem $path | Select Name | Where {$_.Name -like $search}
	foreach ($file in $files) { 
		$logs = $path + $file.Name
		$logs | Out-File -Append "files.txt" -Encoding ASCII
	}
}