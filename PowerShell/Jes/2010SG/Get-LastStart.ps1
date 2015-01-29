<#
	.SYNOPSIS 
		Gathers the last start date for a computer.
	.DESCRIPTION
		Get-LastStart.ps1 gathers the last start date for a computer based on the System Log with the most recent EventID 6005.  This can be run against a remote computer or on the local session using PSSessions.
	.PARAMETER computers
		Remote computers to create query.  Seperate with a comma (,) for multiple computers.
	.PARAMETER file
		File with a list of computers to query.
	.PARAMETER cred
		Run under specified credentials.  The user will be prompted to enter a username and password for script execution.
	.PARAMETER help
		Display help information.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays on the console.
	.EXAMPLE
		C:\PS> .\Get-LastStart.ps1
		Gathers the latest start date from the local computer.
	.EXAMPLE
		C:\PS> .\Get-LastStart.ps1 -computers "Code1","Code2","Code3"
		Gathers the latest start date from each computer listed in -computers.
	.EXAMPLE
		C:\PS> .\Get-LastStart.ps1 -file list.txt
		Gathers the latest start date from each computer contained in list.txt.
	.NOTES
		Name:       Get-LastStart.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/02/2010 22:00 CST
#>
param (
	#Computer(s) to query
	#Seperate with a comma (,) for multiple computers
	[array]$computers,

	#File with a list of computers to query
	[string]$file,

	#Run under specified credentials
	[switch]$cred
)

#create an array list of all computers being queried.
$list = @()
if ($computers) { $list = $computers }
elseif ($file) { $list = gc $file }
else { $list += "localhost" }

#A bug within Test-Connection will return $false when testing the local computer as "." as the response comes from "localhost"
#Replacing "." with "localhost" to allow validation to correctly function
$list = $list | % { $_.Replace(".","localhost") }

#Create sessions on all computers (remote or local)
$sessions = $list | ? { Test-Connection $_ -quiet -Count 1 } | % {
	
	#Gather credentials and create connections if -cred was specified
	if ($cred) { New-PSSession -ComputerName $_ -Credential (Get-Credential) }
	
	#Otherwise, just create connections
	else { New-PSSession -ComputerName $_ }
}

if ($sessions) {
	$command = {
		#Convert any input data into a new object with Property names Machine and LocalStart
		function Convert-Object {
			param (
				$computer,
				$date
			)
			New-Object PSObject -Property @{
				Machine = $computer
				LastStart = $date
			}
		}
		
		#Get the necessary event logs
		$event = Get-EventLog System -instanceid "2147489653" -Newest 1
		
		#If the event log was found use Convert-Object to output the desired format
		#If not report back "Unknown"
		if ($event) { Convert-Object $event.MachineName $event.TimeGenerated }
		else { Convert-Object $env:COMPUTERNAME "Unknown" }
	}
	
	#Start the execution of all tasks simultaneously
	#Note again that $sessions contains the credentials, therefore they are not explicitely required for Invoke-Command
	Invoke-Command -Session $sessions -ScriptBlock $command -ErrorAction SilentlyContinue | Select Machine,LastStart
	
	$sessions | Remove-PSSession
}
else { Write-Host "No sessions available.  Please check the computers names you would like to query and try again." }