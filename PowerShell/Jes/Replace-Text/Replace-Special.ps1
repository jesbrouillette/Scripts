$reg_file = "list.txt"
$old_reg = Get-Content $reg_file
$new_reg = New-Object System.Collections.ArrayList
foreach ($line in $old_reg) {
	$replacement = $line.Replace("D:\\apps\\oracle\\bin\\sqora32.DLL","C:\\oracle\\Ora9208\\bin\\sqora32.DLL")
	$replacement = $replacement.Replace("D:\\apps\\oracle\\bin\\sqora32.DLL","C:\\oracle\\Ora10204\\BIN\\sqora32.DLL")
	$replacement = $replacement.Replace("Oracle in OraHome92","Oracle in ORA9208")
	$replacement = $replacement.Replace("Oracle in OraHome92","Oracle in Ora10204")
	$add_reg = $new_reg.Add("$replacement")
}
$replace_reg = $new_reg | Out-File $reg_file -Force -Encoding ASCII