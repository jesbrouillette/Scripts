function RemoteProc {
	param (
		[string] $name = $(Read-Host "what server do you want to run your process on?"),
		[string] $command = $(Read-Host "what process would you liket to start?"),
		[string] $switch
	)
	
	$ErrorActionPreference = "SilentlyContinue"
	
	$process = Get-WmiObject -Namespace root\CIMV2 -Class Win32_Process -ComputerName $name
	
	if ($switch) {
		$start = $process.Create($command,$switch)
	} else {
		$start = $process.Create($command)
	}
}
RemoteProc "xlwich011m" "notepad.exe"