#Event Scenario
#Your users do not seem to know how to log out of their computers. This is a problem because each evening, a particular application runs as a scheduled task to back itself up to a network share. This occurs before the network backup job takes place. The storage manager has assigned you to write a script that will forcibly log out users from their workstations when a particular program launches. For the purposes of this example, use calc.exe.
#
#Design Points
#When you manually launch calc.exe on the workstation, it should log you out.
#The actual name of the program that launches should be configurable from the command line when your script is run (the script should be able to monitor for the name of any executable).
#Via a dialog box or other graphical device, your script should prompt the user that the workstation will log them out within 60 seconds.
#Design points for creating a force mode and a “nice mode.” The nice mode should check to see if any Word documents or Excel spreadsheets are open. If they are, your script should not log the user out at that time. The script should check back every five minutes to see if the documents or spreadsheets are still open. 

param (
	[string]$program = "calc.exe",	#Program to watch for to trigger the logoff
	[switch]$force					#Force logoff without waiting for users to close Office applications.
)


if ($force) {
	
	#ScriptBlock to run on the computer on the event trigger
	$action = { (gwmi Win32_OperatingSystem).Win32Shutdown(4) }
}
else {
	
	#ScriptBlock to run on the computer on the event trigger
	$action = {
		
		#Function to handle user notification and to wait for Office apps to close if they are open.
		function Wait-ForExit {
			param (
				[int]$wait,
				[datetime]$start
			)
			$msg = "$($program) has been launched and needs all users logged off to function.`nYou will be logged off in " + $wait + " minute(s).`nPlease close all applications.`nWhen you are finished click OK to continue."
			$msgTimer = ($wait * 60) - 5
			$popup = (New-Object -ComObject Wscript.Shell).popup($msg,$msgTimer,"Warning",1)
			do {
				$now = [datetime]::Parse((Get-Date))
				Start-Sleep -Seconds 5
			}
			until (($now -ge ($start.AddMinutes($wait))) -or ($popup -eq 1))
		}
		$start = [datetime]::Parse((Get-Date))
		$checkProc = Get-Process -Name winword,excel
		if ($checkProc) {
			do { Wait-ForExit 5 $start }
			until (!(Get-Process -Name winword,excel))
		}
		else {Wait-ForExit 1 $start }
		(gwmi Win32_OperatingSystem).Win32Shutdown(4)
	}
}

$Query = "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName='" + $program + "'"

Register-WmiEvent -Query $Query -SourceIdentifier ProcessStart -Action $Action