param(
	[switch]$H, #help
	[switch]$M, #monitor
	[string]$Name = $(if (!$Local -and !$H) {Read-Host -prompt "Please enter a machine name to power control"} else {"."}),
	[string]$Comment
)

################################################################################
#                                                                              #
# Purpose:                                                                     #
#                                                                              #
# Execution:                                                                   #
#                                                                              #
# Usage:                                                                       #
#                                                                              #
# Switches:                                                                    #
#                                                                              #
# Example:                                                                     #
#                                                                              #
################################################################################

$ErrorActionPreference = "Continue"

function Start-Reporting() { #Starts the reporting components
	Set-Variable -Name StartTime -value (get-date -format g) -Scope Script

	#Checks for and deletes the temp report file.
	Set-Variable -Name ReplyTmpFile -Value ($Env:TEMP + "\replystatus.txt") -Scope Script
	$Test = Test-Path $ReplyTmpFile
	if ($Test -eq "True") {
		$Remove = Remove-Item -Path $ReplyTmpFile -Force
	}

	$now = Get-Date -Format "h:mm:ss tt"
	Write-Host "reporting started at" $now
}

function Write-EventLog($EvtMachine,$EvtUser,$EvtType,$EvtComment) { #Writes the shutdown event log
	$EventLog = New-Object System.Diagnostics.EventLog("System")
	$EventLog.Source = "Remote Shutdown"
	$EventLog.MachineName = $EvtMachine
	$EventType = [System.Diagnostics.EventLogEntryType]::Information
	$EventDescription = "Shutdown sequence initiated by " + $EvtUser + `
		"`nShutdown Type: " + $EvtType + `
		"`nComment: " + $EvtComment
	$EventLog.WriteEntry($EventDescription,$EventType,1074)
	$now = Get-Date -Format "h:mm:ss tt"
	Write-Host "event log written at" $now
}

function PowerCycle-Station($IntPowerOpt) { #Initiates the shutdown or reboot sequence using WMI
	$OpSys = Get-WmiObject -Class Win32_OperatingSystem
	$PowerCycle = $OpSys.Win32Shutdown($IntPowerOpt,0)
	$now = Get-Date -Format "h:mm:ss tt"
	Write-Host "power sequence initiated at" $now
}

function Ping-Down { #Pings the machine until it stops responding using .NET
	$Reply = "DestinationHostUnreachable"
	$addStatus = $Status.Add("Pinging " + $Name + "`n`nStarted: " + $StartTime)
		
	do {
		$Reply = $Ping.send($Name)
		$now = Get-Date -Format "h:mm:ss tt"
		$addStatus = $Status.Add("Response: " + $Reply.Status + " " + $now)
		Set-Variable -Name Repeat -Value ($Repeat + 1) -Scope Script
		Start-Sleep –s 1
	}
	Until ($Reply.Status -ne "Success")
	Write-Host $Name "is down at" $now
}

function Ping-Up { #Pings the machine until it starts responding using .NET
	do {
		$Reply = $Ping.send($Name)
		$now = Get-Date -Format "h:mm:ss tt"
		$addStatus = $Status.Add("Response: " + $Reply.Status + " " + $now)
		Set-Variable -Name Repeat -Value ($Repeat + 1) -Scope Script
	}
	Until ($Reply.Status -eq "Success")
	
	Set-Variable -Name Address -Value ($Reply.Address) -Scope Script
	$UpTime = Get-Date -Format "h:mm:ss tt"
	$addStatus = $Status.Add("Finished: " + $UpTime + "`n `n Ping attempts: " + $IntRepeat)
	Write-Host $Name "is up at"  $UpTime
}

Function Get-RemoteRegistry {
	param(
		[string]$computer = $(Read-Host "Remote Computer Name"),
		[string]$Path = $(Read-Host "Remote Registry Path (must start with HKLM,HKCU,etc)"),
		[string]$Properties,
		[switch]$Verbose
	)
	if ($Verbose) { $VerbosePreference = 2 } # Only affects this script.
 
	$root, $last = $Path.Split("\")
	$last = $last[-1]
	$Path = $Path.Substring($root.Length + 1,$Path.Length - ( $last.Length + $root.Length + 2))
 
	switch($root) {
		"HKCR"  { $root = "ClassesRoot"}
		"HKCU"  { $root = "CurrentUser" }
		"HKLM"  { $root = "LocalMachine" }
		"HKU"   { $root = "Users" }
		"HKPD"  { $root = "PerformanceData"}
		"HKCC"  { $root = "CurrentConfig"}
		"HKDD"  { $root = "DynData"}
		default { return "Path argument is not valid" }
	}
 
	Write-Verbose "Accessing $root from $computer"
	$rootkey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($root,$computer)
	if(-not $rootkey) { Write-Error "Can't open the remote $root registry hive" }
	 
	Write-Verbose "Opening $Path"
	$key = $rootkey.OpenSubKey( $Path )
	if(-not $key) { Write-Error "Can't open $($root + '\' + $Path) on $computer" }
 
	$subkey = $key.OpenSubKey( $last )
   
	$output = new-object object

	if($subkey -and $Properties -and $Properties.Count) {
		foreach($property in $Properties) { Add-Member -InputObject $output -Type NoteProperty -Name $property -Value $subkey.GetValue($property) }
		Write-Output $output
	} elseif($subkey) {
		Add-Member -InputObject $output -Type NoteProperty -Name "Subkeys" -Value @($subkey.GetSubKeyNames())
		foreach($property in $subkey.GetValueNames()) { Add-Member -InputObject $output -Type NoteProperty -Name $property -Value $subkey.GetValue($property) }
		Write-Output $output
	} else { $key.GetValue($last) }
}

function Watch-CTXReg {
	do {
		$loaded = Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Citrix\IMA\RUNTIME" "CurrentlyLoadingPlugin" $Verbose
		Write-Host $loaded "is loading on" $Name
		$now = Get-Date -Format "h:mm:ss tt"
		$addStatus = $Status.Add($loaded + "is loading on" + $Name + " at " + $now)
		if ($loaded -eq "MfPrintSs.dll") {
			$addStatus = $Status.Add("Shutting down print services on " + $Name + " at " + $now)
			$ctxprnSVC = Get-WmiObject -Computer $name win32_service -filter "name='cpsvc'"
			$mode = $ctxprnSVC.ChangeStartMode("Disabled")
			$stop = $ctxprnSVC.StopService()
			$spoolSVC = Get-WmiObject -Computer $name win32_service -filter "name='Spooler'"
			$mode = $spoolSVC.ChangeStartMode("Disabled")
			$stop = $spoolSVC.StopService()
			$mode = $spoolSVC.ChangeStartMode("Auto")
			$start = $spoolSVC.StartService()
			$mode = $ctxprnSVC.ChangeStartMode("Auto")
			$start = $ctxprnSVC.StartService()
			$addStatus = $Status.Add("Print services restarted on " + $Name + " at " + $now)
		}
		do {
			$loading = Get-RemoteRegistry $RemotePC "HKLM\SOFTWARE\Citrix\IMA\RUNTIME" CurrentlyLoadingPlugin
			Start-Sleep -Seconds 1
		}
		until ($loaded -ne $loading)
	}
	until ($loaded -eq "")
}

function Check-Services { #Monitors the Terminal Services service until it starts using WMI
	Do {
		$Service = Get-WmiObject -ComputerName $Name -class win32_service -filter "name='TermService'"
		Set-Variable -Name ServiceState -Value ($Service.State) -Scope Script
	}
	until ($ServiceState -eq "Running")
	$now = Get-Date -Format "h:mm:ss tt"
	$addStatus = $Status.Add("Services are started on " + $Name + " at " + $now)
	Write-Host "services are started on" $Name "at" $now
}

function End-Reporting { #Finalizes the reporting sequence
	$NameUp = $Name.ToUpper()
	$EndTime = Get-Date -Format g
	$MsgBox = New-Object -comobject wscript.shell
	$Summary = $MsgBox.popup($NameUp + " IS ONLINE AND READY FOR LOGINS`n`nIP: " + $Address + "`nStarted: " + $StartTime + "`nOnline At: " + $EndTime + "`nTerminal Services: " + $ServiceState + "`n`nWould you like to connect to the server? `n`nClick 'NO' to see the results, or 'Cancel' to close",0,"NotifyUp",3)
	
	if ($Summary -eq 6) {
		$RDP = "mstsc.exe /v:" + $Name
		$Open = Invoke-Expression -Command $RDP
	}
	if ($Summary -eq 7) {
		if ($Status.Count -gt 40) {
			$OutReplyStatus = $Status | Out-File -FilePath $ReplyTmpFile -Append -Encoding ASCII
			$Open = Invoke-Expression -Command $ReplyTmpFile
		}
		else {
			foreach ($Line in $Status) {
				$OutReplyStatus = $OutReplyStatus + "`n" + $Line
			}
			$Response = $MsgBox.popup($OutReplyStatus,0,"Ping Response History")
		}
	}
	$now = Get-Date -Format "h:mm:ss tt"
	Write-Host "reporting completed at" $now
}

# End Functions

if ($H) { #Displays help
	$Help = "Restart-Citrix.ps1`n  Reboots or shuts down a remote computer.`n`nUsage:`n.\Restart-Citrix.ps1 computername (-r|-s|-n|-w|-h|-l)`n`nSwitches: (-r or -s is required)`n  -r - reboot`n  -s - shut down`n  -n - no reporting (only used with -s)`n  -w - shut down and wait for a manual reboot (only used with -s)`n  -h - displays this message`n`nExamples:`n  .\Restart-Citrix.ps1 MyComputer -r`n  Reboots the computer named MyComputer`n`n  .\Restart-Citrix.ps1 MyComputer -s /n`n  Shuts Down the computer named MyComputer with no reporting"
	$MsgBox = New-Object -comobject wscript.shell
	$Help = $MsgBox.Popup($Help,0,"Restart-Citrix.ps1")
	exit
}
$Name = $Name.ToUpper()
$UserName = $Env:USERDOMAIN + "\" + $Env:USERNAME

$Status = New-Object System.Collections.ArrayList
$Ping = New-Object System.Net.NetworkInformation.Ping

$Verify = "Do you want to restart " + $Name + "?"
$MsgBox = New-Object -comobject wscript.shell
$Continue = $MsgBox.Popup($Verify,0,"Restart-Citrix.ps1",4)

if ($Continue -eq 7) {
	$Verify = "Restart aborted for " + $Name
	$Notify = $MsgBox.Popup($Verify,0,"Restart-Citrix.ps1",0)
	exit
}

Start-Reporting
Write-EventLog $Name $UserName "Reboot" $Comment
PowerCycle-Station 6
Ping-Down
Ping-Up
Watch-CTXReg
Check-Services
End-Reporting