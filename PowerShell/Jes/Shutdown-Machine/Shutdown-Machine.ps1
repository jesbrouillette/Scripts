param(
	[string]$machine, #single computer to reboot
	[string]$l, #list of servers to issue the same shutdown command
	[string]$comment,
	[switch]$local, #execute on the local computer
	[switch]$h, #help
	[switch]$n, #no reporting
	[switch]$r, #reboot
	[switch]$s, #shutdown
	[switch]$m, #monitor
	[switch]$w, #shutdown and wait for the server to come back online
	[switch]$q #quite mode
)

################################################################################
#                                                                              #
# Purpose:                                                                     #
#     Reboot or shutdown a remote computer                                     #
#                                                                              #
# Execution:                                                                   #
#     Utilizes WMI and .NET to shutdown or reboot a remote or local computer.  #
#     After a successful reboot the user can then choose to reconnect          #
#     using mstsc.exe to the rebooted computer.                                #
#                                                                              #
# Usage:                                                                       #
#     .\Shutdown-Computer.ps1 computername/-local (-r|-s|-m|-n|-w|-h|-l|-c)    #
#     (-m, -r or -s is required)                                               #
#                                                                              #
# Switches:                                                                    #
#     -r : Reboot                                                              #
#     -s : Shutdown                                                            #
#     -m : Monitor a server that is already down - No power sequence           #
#     -n : No reporting                                                        #
#     -w : Wait for the server to come back online after a shutdown (must be   #
#            used with -s)                                                     #
#     -c : Comment to log in the System log                                    #
#     -l : Executes on the local computer                                      #
#     -h : Help                                                                #
#                                                                              #
# Example:                                                                     #
#     .\Shutdown-Computer.ps1 -name MyComputer -r                              #
#     Reboots the computer named MyComputer                                    #
#                                                                              #
#     .\Shutdown-Computer.ps1 -name MyComputer -s -n                           #
#     Shuts Down the computer named MyComputer with no reporting               #
#                                                                              #
#     .\Shutdown-Computer.ps1 -local -r                                        #
#     Reboots the local computer                                               #
#                                                                              #
################################################################################


$errorActionPreference = "SilentlyContinue"

function ReportStart() { #Starts the reporting components
	Set-Variable -Name StartTime -value (get-date -format g) -Scope Script

	#Checks for and deletes the temp report file.
	Set-Variable -Name ReplyTmpFile -Value ($env:TEMP + "\replystatus.txt") -Scope Script
	$test = Test-Path $replyTmpFile
	if ($test -eq "True") { $remove = Remove-Item -Path $replyTmpFile -Force }

	$now = Get-Date -Format "h:mm:ss tt"
	if (!$q) { 	if (!$q) { Write-Host  "reporting started at" $now } }
}

function WriteEvent($evtMachine,$evtUser,$evtType,$evtComment) { #Writes the shutdown event log
	$eventLog = New-Object System.Diagnostics.EventLog("System")
	$eventLog.Source = "RemoteShutdown"
	$eventLog.MachineName = $evtMachine
	$eventType = [System.Diagnostics.EventLogEntryType]::Information
	$eventDescription = "Shutdown sequence initiated by " + $evtUser + `
		"`nShutdown Type: " + $evtType + `
		"`nComment: " + $evtComment
	$eventLog.WriteEntry($eventDescription,$eventType,1074)
	$now = Get-Date -Format "h:mm:ss tt"
		if (!$q) { Write-Host  "event log written at" $now }
}

function OpSysPower($intPowerOpt) { #Initiates the shutdown or reboot sequence using WMI
	if (!$local) {
		$opSys = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $server
	} else {
		$opSys = Get-WmiObject -Class Win32_OperatingSystem
		$powerCycle = $opSys.Win32Shutdown($intPowerOpt,0)
		exit
	}
	$powerCycle = $opSys.Win32Shutdown($intPowerOpt,0)
	$now = Get-Date -Format "h:mm:ss tt"
	if (!$q) { Write-Host  "power sequence initiated at" $now }
}

function PingDown { #Pings the machine until it stops responding using .NET
	$pingdown = 0
	$reply = "DestinationHostUnreachable"
	$addReply = $arrReplyStatus.Add("Pinging " + $server + "`n`nStarted: " + $startTime)
		
	do {
		$reply = $ping.send($server)
		$now = Get-Date -Format "h:mm:ss tt"
		$addReply = $arrReplyStatus.Add("Response: " + $reply.Status + " " + $now)
		Set-Variable -Name Repeat -Value ($repeat + 1) -Scope Script
		Start-Sleep –s 1
		if ($reply.Status -ne "Success") { $pingdown += 1 }
	} 
	Until ($pingdown -ge 5)
	if (!$q) { Write-Host  $server "is down at" $now }
}

function PingUp { #Pings the machine until it starts responding using .NET
	do {
		$reply = $ping.send($server)
		$now = Get-Date -Format "h:mm:ss tt"
		$addReply = $arrReplyStatus.Add("Response: " + $reply.Status + " " + $now)
		Set-Variable -Name Repeat -Value ($repeat + 1) -Scope Script
	}
	Until ($reply.Status -eq "Success")
	
	Set-Variable -Name Address -Value ($reply.Address) -Scope Script
	$upTime = Get-Date -Format "h:mm:ss tt"
	$addReply = $arrReplyStatus.Add("Finished: " + $upTime + "`n `n Ping attempts: " + $intRepeat)
	if (!$q) { Write-Host  $server "is up at"  $upTime }
}

function SvcCheck { #Monitors the Terminal Services service until it starts using WMI
	Do {
		$service = Get-WmiObject -ComputerName $server -class win32_service -filter "name='TermService'"
		Set-Variable -Name ServiceState -Value ($service.State) -Scope Script
	}
	until ($serviceState -eq "Running")
	$now = Get-Date -Format "h:mm:ss tt"
	$addReply = $arrReplyStatus.Add("Services are started on " + $server + " at " + $now)
	if (!$q) { Write-Host  "services are started on" $server "at" $now }
}

function ReportEnd { #Finalizes the reporting sequence
	$serverUp = $server.ToUpper()
	$endTime = Get-Date -Format g
	$msgBox = New-Object -comobject wscript.shell
	if (!$q) { $summary = $msgBox.popup($serverUp + " IS ONLINE AND READY FOR LOGINS`n`nIP: " + $address + "`nStarted: " + $startTime + "`nOnline At: " + $endTime + "`nTerminal Services: " + $serviceState + "`n`nWould you like to connect to the server? `n`nClick 'NO' to see the results, or 'Cancel' to close",0,"NotifyUp",3) }
	
	if ($summary -eq 6 -and !$q) {
		$rDP = "mstsc.exe /v:" + $server
		$open = Invoke-Expression -Command $rDP
	} elseif ($summary -eq 7 -and !$q) {
		if ($arrReplyStatus.Count -gt 40) {
			$outReplyStatus = $arrReplyStatus | Out-File -FilePath $replyTmpFile -Append -Encoding ASCII
			$open = Invoke-Expression -Command $replyTmpFile
		} else {
			foreach ($line in $arrReplyStatus) { $outReplyStatus = $outReplyStatus + "`n" + $line }
			$response = $msgBox.popup($outReplyStatus,0,"Ping Response History")
		}
	}
	$now = Get-Date -Format "h:mm:ss tt"
	if (!$q) { Write-Host "reporting completed at" $now }
}

# End Functions
if (!$local -and !$h -and !$l -and !$machine) { $machine = Read-Host -prompt "Please enter a machine name to power control" }
 
if ($l) { $machines = Get-Content $l }
else { $machines = $machine }

if (!$q) { $msgBox = New-Object -comobject wscript.shell }

foreach ($server in $machines) {
	$server = $server.ToUpper()
	$userName = $env:USERDOMAIN + "\" + $env:USERNAME
	
	$arrReplyStatus = New-Object System.Collections.ArrayList
	$ping = New-Object System.Net.NetworkInformation.Ping

	if ($h -or !($r -or $s -or $m -or $w)) { #Displays help
		$help = "Shutdown-Computer.ps1`n  Reboots or shuts down a remote computer.`n`nUsage:`n.\Shutdown-Computer.ps1 computername (-r|-s|-n|-w|-h|-l)`n`nSwitches: (-r or -s is required)`n  -r - reboot`n  -s - shut down`n  -n - no reporting (only used with -s)`n  -w - shut down and wait for a manual reboot (only used with -s)`n  -h - displays this message`n`nExamples:`n  .\Shutdown-Computer.ps1 MyComputer -r`n  Reboots the computer named MyComputer`n`n  .\Shutdown-Computer.ps1 MyComputer -s /n`n  Shuts Down the computer named MyComputer with no reporting"
		$help = $msgBox.Popup($help,0,"Shutdown-Computer.ps1")
		exit
	}
	
	if ($r){ $powerOpt = "reboot" }
	elseif ($m) { $powerOpt = "power monitor" }
	else { $powerOpt = "shutdown" }
	
	$verify = "Do you want to execute a " + $powerOpt + " on:`n`n`t" + $server
	if (!$q) { 
		$msgBox = New-Object -comobject wscript.shell
		$continue = $msgBox.Popup($verify,0,"Shutdown-Machine.ps1",4)
	}
	
	if ($continue -eq 7 -and !$q) {
		$verify = "Shutdown aborted for " + $server
		$notify = $msgBox.Popup($verify,0,"Shutdown-Machine.ps1",0)
		exit
	}
	
	if (!$local) { $intRepeat = 0 }
	else {
	#Local
		if ($r) {
			WriteEvent $server $userName "Reboot" $comment
			OpSysPower 6
		} elseif ($s) {
			WriteEvent $server $userName "Shutdown" $comment
			OpSysPower 5
		}
		exit
	}
	
	#Reboot Sequence
	if ($r) {
		ReportStart
		WriteEvent $server $userName "Reboot" $comment
		OpSysPower 6
		PingDown
		PingUp
		SvcCheck
		ReportEnd
	}
	
	#Power Off Sequence
	elseif ($s -or $w) {
		if (!$n) { ReportStart } #Skip for Power Off with no reporting
		WriteEvent $server $userName "Shutdown" $comment
		OpSysPower 5
		PingDown
		if ($w) { #Power Off and wait for manual reboot
			PingUp
			SvcCheck
		}
		if (!$n) { ReportEnd } #Skip for Power Off with no reporting
	}
	
	#Monitor Sequence
	elseif ($m) {
		ReportStart
		PingUp
		SvcCheck
		ReportEnd
	}
}