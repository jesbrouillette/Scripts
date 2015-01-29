if ($Error) { $Error.Clear() }

$list = Import-Csv "C:\source\Library\MWTS\printer_drivers\printerdrivers.csv"
$log = "C:\Source\Library\MWTS\printer_drivers\install_printers.csv"

switch ((gwmi win32_computersystem).SystemType) {
	"x64-based PC" { $type = "Windows x64" }
	"X86-based PC" { $type = "Windows NT x86" }
	default { $type = "Windows NT x86" }
}

$list | % {
	if ($_.'os ver' -eq $type) {
		Write-Host "$($_.driver) for $($_.'os ver') : $($_.inf) : " -NoNewline	
		cmd /c start /wait rundll32 printui.dll,PrintUIEntry /ia /K /m "$($_.driver)" /h "$type" /v 3 /f "$($_.path)\$($_.inf)"
		if ($Error) {
			Write-Host $Error[0].Exception.Message
			$status = $Error[0].Exception.Message
			$Error.Clear() }
		else {
			Write-Host "Success"
			$status = "Success"
		}
	}
	$_
} | Select @{N="Driver";E={$($_.driver)}},`
	@{N="OS_Version";E={$_.'os ver'}},`
	@{N="File";E={"$($_.path)\$($_.inf)"}},`
	@{N="Status";E={$status}},`
	@{N="Server";E={$ENV:COMPUTERNAME}},`
	@{N="TimeStamp";E={Get-Date}} | Export-Csv $log -NoType -Force