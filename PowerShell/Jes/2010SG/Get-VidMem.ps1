<#
	.SYNOPSIS 
		Gathers video memory from a computer.
	.DESCRIPTION
		Get-VidMem.ps1 gathers the memory amounts of all video cards present on a give computer.  This can be run against a remote computer or on the local session.
	.PARAMETER computers
		Remote computers to create the variable in.  Seperate with a comma (,) for multiple computers.
	.PARAMETER file
		File with a list of computers to create the variable in.
	.PARAMETER logpath
		Alternate storage location for the log file.
	.PARAMETER logfile
		Alternate name for the log file.  Get-VidMem_Results.csv will be used if not specified.
	.PARAMETER append
		Append the log file if it exists.
	.PARAMETER cred
		Run under specified credentials.  The user will be prompted to enter a username and password for script execution.
	.PARAMETER quiet
		Run silently.
	.PARAMETER help
		Display help information.
	.INPUTS
		None. Piped objects are not accepted.
	.OUTPUTS
		Set-EnvVar_log.csv is created within the same directory as the script.
	.EXAMPLE
		C:\PS> .\Get-VidMem.ps1
		Gathers video card information from the local computer.  Output is displayed on screen and logged in Get-VidMem_Results.csv.
	.EXAMPLE
		C:\PS> .\Get-VidMem.ps1 -computers "Code1","Code2","Code3" -quiet
		Gathers video card information from each computer listed in -computers.  Output is only sent to Get-VidMem_Results.csv.
	.EXAMPLE
		C:\PS> .\Get-VidMem.ps1 -file list.txt -logpath "C:\LOGS" -logfile "Get-VideoMemory_All.csv"
		Gathers video card information from each computer contained in list.txt and saves the log file as C:\LOGS\Get-VideoMemory_All.csv"
	.NOTES
		Name:       Get-VidMem.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  04/30/2010 00:38 CST
#>
param (
	#Computer(s) to create the variable in.  Seperate with a comma (,) for multiple computers
	[array]$computers,

	#File with a list of computers to create the variable in
	[string]$file,

	#Path to store the log file
	[string]$logPath,

	#Alternate name for the log file
	[string]$logFile = "Get-VidMem_Results.csv",

	#Append the log file
	[switch]$append,		

	#Run under specified credentials
	[switch]$cred,		

	#Runs silently and only generates a log file
	[switch]$quiet		
)

#Report function for all server not online
function Report-NotOnline {
	<#
		.SYNOPSIS
			Generate and object containing the computer name, Online status as $false, and the current date/time
		.PARAMETER computername
			String value of the computer to report
		.INPUT
			Accepts one string value
	#>
	param([string]$computer)
	
	#Although the only properties being reported back are Computer Online and Date, Select after the pipe will create the remaining properties as $null
	New-Object PSObject -Property @{
		Computer = $computer
		Online = $false
		Date = (Get-Date -Format g)
	}
}

#Validate the user specified path
if (!$logPath) { $log = $logFile }
elseif (Test-Path $logPath) {
	
	#Replace double-backslashes (\\) with triple to prevent the next peice from breaking UNC storage locations
	if ($logPath -match "\\") { $logPath = $logPath.Replace("\\","\\\") }
	
	#Place a backslash (\) between the logPath and logFile incase it was left out of the path
	#Remove double-backslashes (\\) if one was input already
	$log = ($logPath + "\" + $logFile).Replace("\","\\")
}
else { Write-Host "The logging directory specified is not valid.  Please specify a valid path and try again." ; exit } 

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

#Build the command script block to pass into Invoke-Command later
$command = {
	
	#Convert $bytes to MB if it is less then 1GB and convert to GB if it greater than or equal to 1GB
	function ConvertFrom-Bytes {
		<#
			.SYNOPSIS
				Converts from Bytes to MB or GB with two decimal places
			.PARAMETER $bytes
				Int32 value to convert
			.INPUT
				Accepts one Int32
		#>
		param ([Int32]$bytes)
		switch ($bytes) {
			{ $bytes -lt 1gb } { ([Math]::Round($bytes/1mb,2)).ToString() + "MB" }
			Default { ([Math]::Round($bytes/1gb,2)).ToString() + "GB" }
		}
	}
	
	#Return $true if $bytes is less than 128MB
	function Check-UpgradeNeed {
		<#
			.SYNOPSIS
				Returns $true if the byte size is less than 128MB and $false if it is greater than or equal to 128MB
			.PARAMETER $bytes
				Int32 value to check
			.INPUT
				Accepts one Int32
		#>
		param ([Int32]$bytes)
		switch ($bytes) {
			{ $bytes -lt 128mb } { $true }
			Default { $false }
		}
	}

	#Query the Win32_VideoController WMI class for all video cards
	#This will help determin upgrade requirements on all video cards, not just the primary
	gwmi Win32_VideoController |
	
	#Only return the desired properties to keep the execution as light-weight as possible
	Select VideoProcessor,SystemName,DeviceID,AdapterRAM | % { 
		
		#Although we have many of our existing properties the Property Names are a bit ambiguous and we need to add more properties
		#Instead of using Add-Property for the extras we can accomplish the Property Name rename and add additional properties through a single object
		New-Object PSObject -Property @{
			Computer = $_.SystemName
			VideoCard = $_.VideoProcessor
			Device = $_.DeviceID
			
			#Calculating memory size as MB or GB
			VideoMemory = ConvertFrom-Bytes $_.AdapterRAM
			
			#Determine upgrade needs
			NeedsUpgraded = Check-UpgradeNeed $_.AdapterRAM
			Online = $true
			Date = (Get-Date -Format g)
		}
	}
}

#Create the $data object and collect all information into this object
$data = @( & {
	
	#Report if no sessions were able to be generated
	if (!$sessions) {
		$list | % { Report-NotOnline } | Select Computer,VideoCard,Device,VideoMemory,NeedsUpgraded,Online,Date
	}
	else {
		
		#Start the execution of all tasks simultaneously
		#Note again that $sessions contains the credentials, therefore they are not explicitely required for Invoke-Command
		Invoke-Command -Session $sessions -ScriptBlock $command -ErrorAction SilentlyContinue |	Select Computer,VideoCard,Device,VideoMemory,NeedsUpgraded,Online,Date
	
		#This will output any non-active computer by compairing the full list of computers with those that a upon which a sessions was able to opened
		#By keeping this and Invoke-Command with the same $data object, they are able to be gathered verry efficiently
		$list | ? {
			
			#Build an array list of all computer names withn a session and compair its contents with the item being passed through the pipe
			@($sessions | % { $_.ComputerName } ) -notcontains $_
		} | % { Report-NotOnline } | Select Computer,VideoCard,Device,VideoMemory,NeedsUpgraded,Online,Date
		
		#Remove all open PSSessions
		$sessions | Remove-PSSession
	}
#Note the trailing Close Parentheses as the $data object is being completed
} )

#Write data gathered to the console if -quiet was not specified
if (!$quiet) { $data | FT }

#Add existing log information into the new $data object if -append was selected
if ((Test-Path $log) -and $append) {
	Import-Csv $log | % { $data += $_ }
}

#Write data to $log in the running directory
$data | Export-Csv $log -NoTypeInformation -Force