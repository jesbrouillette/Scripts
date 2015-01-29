<#
	.SYNOPSIS 
		Gathers the last start date for a computer.
	.DESCRIPTION
		Get-LastStart.ps1 gathers the last start date for a computer based on the System Log with the most recent EventID 6005.  This can be run against a remote computer or on the local session using PSSessions.
	.PARAMETER computers
		Remote computers to create query.  Seperate with a comma (,) for multiple computers.
	.PARAMETER file
		File with a list of computers to query.
	.PARAMETER computers
		List of computers to query.
	.PARAMETER eventlog
		EventLog to query.
	.PARAMETER eventID
		EventID to return from the EventLog.
	.PARAMETER cred
		Run under specified credentials.  The user will be prompted to enter a username and password for script execution.
	.PARAMETER start
		Display help information.
	.PARAMETER events
		Specify the number of events to return.
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
		Purpose:	2010 Scripting Games: Advanced Event 2--Retrieving Workstation Start Time
#>
param (
	#List of computers to query.
	[parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
	[array]$computers,
	
	#File with a list of computers to query.
	[parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
	[string]$file,
	
	#EventLog to query.
	[parameter(Position=2,ValueFromPipelineByPropertyName=$true)]
	[string]$eventlog = "System",
	
	#EventID to return from the EventLog.
	[parameter(Position=3,ValueFromPipelineByPropertyName=$true)]
	[string]$eventID,
	
	#Run under specified credentials.  The user will be prompted to enter a username and password for script execution.
	[parameter(Position=4,ValueFromPipelineByPropertyName=$false)]
	[switch]$cred,
	
	#Start date of query.
	[parameter(Position=5,ValueFromPipelineByPropertyName=$true)]
	[datetime]$start = (Get-Date "1/1/1"),

	#End date of query.
	[parameter(Position=6,ValueFromPipelineByPropertyName=$true)]
	[datetime]$end = (get-date),
	
	#Number of event items to return
	[parameter(Position=7,ValueFromPipelineByPropertyName=$true)]
	[int]$events,

	#Description to query
	[parameter(Position=8,ValueFromPipelineByPropertyName=$true)]
	[string]$description
)

#create an array list of all computers being queried.
$list = @()
if ($computers) { $list = $computers }
elseif ($file) { $list = gc $file }
else { $list += "localhost" }

if (!$eventID -and !$description) { $eventID = "6005" }

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
		param (
			#EventLog to query.
			[parameter(	Position=0,ValueFromPipelineByPropertyName=$true)]
			[string]$eventlog,
			
			#EventID to return from the EventLog.
			[parameter(	Position=1,ValueFromPipelineByPropertyName=$true)]
			[string]$eventID,
			
			#Number of event items to return
			[parameter(	Position=2,ValueFromPipelineByPropertyName=$true)]
			[datetime]$start,
		
			#End date of query.
			[parameter(Position=3,ValueFromPipelineByPropertyName=$true)]
			[datetime]$end,
					
			#Number of event items to return
			[parameter(	Position=4,ValueFromPipelineByPropertyName=$true)]
			[int]$events,
					
			#Description to query
			[parameter(	Position=5,ValueFromPipelineByPropertyName=$true)]
			[string]$description
		)
		
		#Get the necessary event logs
		if (!$eventID) { $event = gwmi Win32_NTLogEvent -Filter "LogFile='$($eventlog)'" | Select LogFile,EventCode,ComputerName,TimeGenerated,Message,Type,User -ExcludeProperty "_*" }
		else { $event = gwmi Win32_NTLogEvent -Filter "LogFile='$($eventlog)' AND EventCode='$($eventID)'" | Select LogFile,EventCode,ComputerName,TimeGenerated,Message,Type,User -ExcludeProperty "_*" }
		
		#If the event log was found use Convert-Object to output the desired format
		#If not report back "Unknown"
		if ($event) {
			$event = $event | % {
			
				#Convert the TimeGenerated into a standard readable format
				$date = [datetime]::ParseExact((($_.TimeGenerated).Split("."))[0],"yyyyMMddHHmmss",$null)
				if (($date -le $end) -and ($date -ge $start)) {
					Add-Member -MemberType NoteProperty -Name Time -Value $date -InputObject $_
				}
				$_
			}
		}
		
		#Filter based on the description if specified.
		if ($event -and $description) {	$event = $event | ? { $_.Message -match $description } }
		
		#Select only the first number of events as specified in events.
		if ($event -and $events) { $event = $event | select -First $events }
		
		#Report basic information if no event log was found.
		#Include any error messages received during the process.
		elseif (!$event) {
			$event = New-Object PSObject -Property @{
				LogFile = $eventlog
				EventCode = $eventID
				ComputerName = $env:COMPUTERNAME
				Time = "Unknown"
				Message = $Error[0].Exception.Message
				Type = ""
				User = ""
			}
		}
		
		#Send the event back to the local console from the remote session.
		$event | Select * -ExcludeProperty TimeGenerated
	}
	
	#Start the execution of all tasks simultaneously
	#Note again that $sessions contains the credentials, therefore they are not explicitely required for Invoke-Command
	Invoke-Command -Session $sessions -ScriptBlock $command -ArgumentList $eventLog,$eventID,$start,$end,$events,$description | select LogFile,EventCode,ComputerName,Message,Type,User,Time | % {
		if (($_.Time -le $end) -and ($_.Time -ge $begin)) {
			
			#Report the last start time if another event was not specified.
			#Report the event if it was.
			if ($_.EventCode -eq "6005") { Write-Host "$($_.Computername) last started at $($_.Time)" }
			else { $_ }
		}
	}
	
	#Close all open PSSessions
	$sessions | Remove-PSSession
}
else { Write-Host "No sessions available.  Please check the computers names you would like to query and try again." }