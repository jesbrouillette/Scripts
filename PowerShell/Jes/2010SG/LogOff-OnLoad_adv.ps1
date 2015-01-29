<#
	.SYNOPSIS 
		Logs off local users when a specified application is launched.
	.DESCRIPTION
		LogOff-OnLoad.ps1 registers a new WMI Event that watches for a specified application to load.  When it does, the event causes the local users to be logged off.
		If the user is running Word or Excel (or any array within waitfor) they will be notified of the shutdown.  They are then allowed to continue to work, but will be reminded every 5 min.  If they choose "Ok" the will be logged out.  If not the script will continue to check every 5 minutes for the existence of the open Office applications.
		If the -force switch is used users will not be notified of any attempt to log them out.
	.PARAMETER trigger
		Specified application to monitor for.
	.PARAMETER waitfor
		Application names to wait for the user exit before logging off.
	.PARAMETER force
		Forcably logoff the users without notification even if Office applications are running.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays a popup for user notification before logoff.
	.EXAMPLE
		C:\PS> .\LogOff-OnLoad.ps1
		Logs users off once calc.exe starts with notification.
	.EXAMPLE
		C:\PS> .\LogOff-OnLoad.ps1 -trigger "winword.exe" -force
		Logs users off once winword.exe starts without notification.
	.NOTES
		Name:       LogOff-OnLoad.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/07/2010 13:30 CST
		Purpose:	2010 Scripting Games: Advanced Event 9--Logging Out Users Forcibly Based on a Program's Launch
#>
[CmdletBinding()]
param (
	#Application to monitor for execution.
	[parameter(Position=0,HelpMessage='Program name to monitor that will trigger the logoff process.')]
	[ValidatePattern(".exe|.cmd|.com|.scr")]
	[string]$trigger = "calc.exe",
	
	#Force logoff without waiting for users to close Office applications.
	[parameter(Position=1,HelpMessage='Program name(s) to wait for the user to close before loging off.')]
	[array]$waitfor = @("winword","excel"),

	#Force logoff without waiting for users to close Office applications.
	[parameter(Position=2)]
	[switch]$force
)

BEGIN {
	#Function to create a popup message.
	function Global:Notify-User {
		param(
			[string]$msg,
			[int]$msgTimer
		)
		(New-Object -ComObject Wscript.Shell).popup($msg,$msgTimer,"Warning",1)
	}
	
	#Function to wait for the user to exit office applications or continues if not open.
	function Global:Wait-ForExit {
		param (
			[int]$wait,			#Number of minutes to delay
			[datetime]$start	#Time to calculate from
		)
		
		#Calculates the popup message to be displayed
		$msg = "$($trigger) has been launched and needs all users logged off to function.`nYou will be logged off in " + $wait + " minute(s).`nPlease close all applications.`nWhen you are finished click OK to logoff immediately."
		
		#Calculate max time for the popup window.
		$msgTimer = ($wait * 60) - 5
		
		#Display the user notification popup.
		$popup = Notify-User $msg $msgTimer
		
		#Loop to count up to the time from the start of the function based on $wait.
		#The loop will also stop if the user clicked "OK" on the popup
		do {
			$now = [datetime]::Parse((Get-Date))
			Start-Sleep -Seconds 5
		}
		until (($now -ge ($start.AddMinutes($wait))) -or ($popup -eq 1))
	}
	[string]$global:trigger = $trigger
	[array]$global:waitfor = $waitfor
	[switch]$global:force = $force

	#WMI Query that will be registred as a WMIEvent
	$query = "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName='" + $trigger + "'"
	
	#SourceIdentifier name.
	#This will allow multiple instances of the script to create monitors for multiple applications.
	$sourceID = "SourceID_" + $trigger.Split(".")[0]
	
	#Message to display in the event.
	$msgData = "$($program) started"
}

PROCESS {
	$action = {
		if (!$force) {
			#Get the current time
			$start = [datetime]::Parse((Get-Date))
			
			#Gather running process for winword and excel
			$checkProc = Get-Process -Name $waitfor
			
			#If they are running start the Wait-ForExit function for 5 minutes from $now
			if ($checkProc) {
				do { Wait-ForExit 5 $start }
				until (!(Get-Process -Name $waitfor))
			}
			else {Wait-ForExit 1 $start }
		}
		(gwmi Win32_OperatingSystem).Win32Shutdown(4)
	}
}

END {
	#Unregister any existing events with the same sourceid
	Get-EventSubscriber -SourceIdentifier $sourceID -ErrorAction SilentlyContinue | Unregister-Event
	
	#Registers the WMIEvent with the action specified in one of the ScriptBlocks above.
	Register-WmiEvent -Query $query -SourceIdentifier $sourceID -Action $action -MessageData $msgData
}