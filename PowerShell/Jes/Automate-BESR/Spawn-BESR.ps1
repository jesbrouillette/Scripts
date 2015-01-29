$processes = @()

$list = Import-Csv "list.csv"

$Log = "Automate-BESR_" + (Get-Date -format "MM-dd-yy_HH.mm.ss") + ".csv"
"Server,Status,TimeStamp,Error" | Out-File $Log -Force -Encoding ASCII

foreach ($item in $list) {
	$row = "" | Select Server,Drives,Process,Started
	$server = $item.server
	$drives = $item.drives
	$backup = $item.backuplocation
	$movegroup = $item.movegroup
	$notify = $item.notify
	$options = ".\Automate-BESR.ps1 -server " + $server + " -drives " + $drives + " -backuplocation " + $backup + " -logfile " + $Log + " -movegroup " + $movegroup.ToUpper() + " -notify " + $notify
	write-host $options
	$row.Server = $server.ToUpper()
	$row.Drives = $drives
	$row.Process = [system.diagnostics.process]::start("powershell.exe",$options)
	$row.Started = (Get-Date).ToString()
	$processes += $Row
}

do {
	$check = @()
	$exited = $true
	
	Start-Sleep -Seconds 15
	
	foreach ($process in $processes) {
		$row = "" | Select Server,Drives,Completed,StartedTime,CompletedTime
		if (!$process.Process.HasExited) { $exited = $false }
		$row.Server = $Process.Server
		$row.Drives = $process.Drives
		$row.Completed = $process.Process.HasExited
		$row.StartedTime = $process.Started
		if ($process.Process.ExitTime) { $row.CompletedTime = $process.Process.ExitTime.ToString() }
		$check += $row
	}
	cls
	$check | Select Server,Drives,Completed,StartedTime,CompletedTime | ft -auto
}
until ( $exited -eq $true )