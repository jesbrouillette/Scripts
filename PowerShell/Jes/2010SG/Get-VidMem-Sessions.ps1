<#
.SYNOPSIS 
Sets remote and local environment variables

.DESCRIPTION
Set-EnvVar.ps1 sets variables for either the User or System enviroments.  This can be run against a remote computer or on a local session.

.PARAMETER name
Variable name

.PARAMETER value
Variable value

.PARAMETER user
Create the variable in the User space

.PARAMETER system
Create the variable in the System space

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
None. You cannot pipe objects to Set-EnvVar.ps1.

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

$list = @()
if ($computers) { $list = $computers }
elseif ($file) { $list = gc $file }
else { $list += "localhost" }
$list = $list | % { $_.Replace(".","localhost") }

$sessions = $list | ? { Test-Connection $_ -quiet -Count 1 } | % {
	if ($cred) { New-PSSession -ComputerName $_ -Credential (Get-Credential) }
	else { New-PSSession -ComputerName $_ }
}

if (!$sessions) {
	$list | % {
		New-Object PSObject -Property @{
			Computer = $_
			Online = $false
		}
	} | Select Computer,VideoCard,Device,VideoMemory,IsUpgradable,Online | Format-Table
	exit
}

$command = {
	gwmi Win32_videoController |
	Select VideoProcessor,SystemName,DeviceID,AdapterRAM |
	% { 
		New-Object PSObject -Property @{
			Computer = $_.SystemName
			VideoCard = $_.VideoProcessor
			Device = $_.DeviceID
			VideoMemory = if ($_.AdapterRAM -gt 1gb) { ($_.AdapterRAM/1gb).ToStrin() + "MB" } else { ($_.AdapterRAM/1mb).ToString() + "MB" }
			IsUpgradable = if ($_.AdapterRAM -ge 128mb) {$true} else {$false}
			Online = $true
		}
	}
}

$data = & {
	Invoke-Command -Session $sessions -ScriptBlock $command -ErrorAction SilentlyContinue |	Select Computer,VideoCard,Device,VideoMemory,IsUpgradable,Online
	$list | ? {
		@($sessions | % { $_.ComputerName } ) -notcontains $_
	} | % {
		New-Object PSObject -Property @{
			Computer = $_
			Online = $false
		}
	} | Select Computer,VideoCard,Device,VideoMemory,IsUpgradable,Online
}

$data | Export-Csv file.csv -NoTypeInformation
if (!$quiet) { $data | FT }

$sessions | Remove-PSSession
