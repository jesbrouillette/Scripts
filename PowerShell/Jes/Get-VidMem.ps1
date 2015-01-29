<#
.SYNOPSIS 
Sets remote and local environment variables

.DESCRIPTION
Set-EnvVar.ps1 sets variables for either the User or System enviroments.  This can be run against a remote computer or on a local session.

.PARAMETER computers
Remote computer(s) to create the variable in.  Seperate with a comma (,) for multiple computers.

.PARAMETER file
File with a list of computers to create the variable in

.PARAMETER cred
Run under specified credentials.  The user will be prompted to enter a username and password for script execution

.PARAMETER quiet
Run silently

.PARAMETER help
Display help information

.INPUTS
String. The script will accept piped strings for computer names to query

.OUTPUTS
Set-EnvVar.ps1 outputs Set-EnvVar_log.csv in the same directory as the script

.EXAMPLE
C:\PS> .\Set-EnvVar.ps1 -name CodeRed -value 1980s -system
A system variable will be created with the name CodeRed and value of 1980s.  Output will be shown on the console.  Since neither -file or -computers is used, the script will run locally.

.EXAMPLE
C:\PS> .\Set-EnvVar.ps1 -name CodeRed -value 1980s -user -file list.txt -quiet
A variable with the name CodeRed will be created in the User space with a value of 1980s.  The file list.txt will be parsed for contents and all devices in the list will be updated.  This will be done silently and a log file created as normal.

.NOTES
Name:       Set-EnvVar.ps1
Author:     Jes Brouillette (ThePosher)
Last Edit:  04/30/2010 00:38 CST
#>
param (
	[array]$computers,	#Remote computer(s) to create the variable in.  Seperate with a comma (,) for multiple computers
	[string]$file,		#File with a list of computers to create the variable in
	[switch]$cred,		#Run under specified credentials
	[switch]$quiet		#Silent.  Only generates a log file
)

# Style points given for reusable code.
# Your script should automatically determine the units to display the video memory.
# Your script should be able to run against multiple remote computers at same time.
# Your script should ensure that a remote computer is reachable before attempting the connection to retrieve the video RAM.
# If the memory is less than 128 MB, your script should state that the computer must be upgraded.
# If the memory is 128 MB or more, your script should state that the computer is ready to be upgraded. 

if ($input) { $list = $input }
elseif ($computers) { $list = $computers }
elseif ($file) { $list = gc $file }
else { $list = "." }

function Calc-VidMem {
	# VideoProcessor,SystemName,DeviceID,AdapterRAM
	New-Object PSObject -Property @{
		Computer = $input.SystemName
		VideoCard = $input.VideoProcessor
		Device = $input.DeviceID
		Memory = if ($input.AdapterRAM > 1gb) { $input.AdapterRAM/1gb } else { $input.AdpaterRAM/1mb }
	}
}

if ($cred) { $credentials = Get-Credential }

$list | % {
	if ($credentials) {
		gwmi Win32_videoController -ComputerName $_ -Credential $credentials | Select VideoProcessor,SystemName,DeviceID,AdapterRAM | % {
			Calc-VidMem
		}
	}
	else {
		gwmi Win32_videoController -ComputerName $_ | Select VideoProcessor,SystemName,DeviceID,AdapterRAM | % {
			Calc-VidMem
		}
	}
}