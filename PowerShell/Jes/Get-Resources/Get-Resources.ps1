$log = "PerfLog_" + (Get-Date -uformat "%d_%m_%Y") + ".csv"
$now = (Get-Date).ToString()
$processes = Get-Process

if ((Test-Path $log) -ne $True) {
	$myObj = @()
	foreach ($process in $processes) { 
		$row = "" | Select BasePriority,Handle,HandleCount,Id,MaxWorkingSet,MinWorkingSet,NonpagedSystemMemorySize,PagedMemorySize,PagedSystemMemorySize,PeakPagedMemorySize,PeakVirtualMemorySize,PeakWorkingSet,PrivateMemorySize,PrivilegedProcessorTime,ProcessName,ProcessorAffinity,Responding,SessionId,StartTime,TotalProcessorTime,UserProcessorTime,VirtualMemorySize,WorkingSet,TimeStamp
		$row.BasePriority = $process.BasePriority
		$row.Handle = $process.Handle
		$row.HandleCount = $process.HandleCount
		$row.Id = $process.Id
		$row.MaxWorkingSet = $process.MaxWorkingSet
		$row.MinWorkingSet = $process.MinWorkingSet
		$row.NonpagedSystemMemorySize = $process.NonpagedSystemMemorySize
		$row.PagedMemorySize = $process.PagedMemorySize
		$row.PagedSystemMemorySize = $process.PagedSystemMemorySize
		$row.PeakPagedMemorySize = $process.PeakPagedMemorySize
		$row.PeakVirtualMemorySize = $process.PeakVirtualMemorySize
		$row.PeakWorkingSet = $process.PeakWorkingSet
		$row.PrivateMemorySize = $process.PrivateMemorySize
		$row.PrivilegedProcessorTime = $process.PrivilegedProcessorTime
		$row.ProcessName = $process.ProcessName
		$row.ProcessorAffinity = $process.ProcessorAffinity
		$row.Responding = $process.Responding
		$row.SessionId = $process.SessionId
		$row.StartTime = $process.StartTime
		$row.TotalProcessorTime = $process.TotalProcessorTime
		$row.UserProcessorTime = $process.UserProcessorTime
		$row.VirtualMemorySize = $process.VirtualMemorySize
		$row.WorkingSet = $process.WorkingSet
		$row.TimeStamp = $now
		$myObj += $row
	}
	$myObj | Export-Csv $log -NoTypeInformation
	RV myObj
	RV row
} else {
	foreach ($process in $processes) {
		$line = [string]$process.BasePriority + "," + [string]$process.Handle + "," + [string]$process.HandleCount + "," + [string]$process.Id + "," + [string]$process.MaxWorkingSet + "," + [string]$process.MinWorkingSet + "," + [string]$process.NonpagedSystemMemorySize + "," + [string]$process.PagedMemorySize + "," + [string]$process.PagedSystemMemorySize + "," + [string]$process.PeakPagedMemorySize + "," + [string]$process.PeakVirtualMemorySize + "," + [string]$process.PeakWorkingSet + "," + [string]$process.PrivateMemorySize + "," + [string]$process.PrivilegedProcessorTime + "," + [string]$process.ProcessName + "," + [string]$process.ProcessorAffinity + "," + [string]$process.Responding + "," + [string]$process.SessionId + "," + [string]$process.StartTime + "," + [string]$process.TotalProcessorTime + "," + [string]$process.UserProcessorTime + "," + [string]$process.VirtualMemorySize + "," + [string]$process.WorkingSet + "," + [string]$process.TimeStamp + "," + $now
		$line | Out-File $log -Append -Encoding ASCII
	}
}