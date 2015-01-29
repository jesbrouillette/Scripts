$ErrorActionPreference = "SilentlyContinue"
$process = ([System.Diagnostics.Process]::Start($args[0],$args[1])).WaitForExit()
if ($Error[0]) {
	$Error[0].Exception.Message
	$clear = $Error.Clear
}