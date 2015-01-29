<#
	.SYNOPSIS 
		Gathers cpu information from a computer.
	.DESCRIPTION
		Get-CPUInfo.ps1 gathers the cpu information via WMI on a give computer.  This can be run against a remote computer or on the local session using PSSessions.
	.PARAMETER computers
		Remote computers to create query.  Seperate with a comma (,) for multiple computers.
	.PARAMETER file
		File with a list of computers to query.
	.PARAMETER cred
		Run under specified credentials.  The user will be prompted to enter a username and password for script execution.
	.PARAMETER help
		Display help information.
	.INPUTS
		None. Piped objects are not accepted.
	.OUTPUTS
		Outputs to the screen or .Net 3.0 or higher GridView.
	.EXAMPLE
		C:\PS> .\Get-CPUInfo.ps1
		Gathers cpu information from the local computer.
	.EXAMPLE
		C:\PS> .\Get-CPUInfo.ps1 -computers "Code1","Code2","Code3"
		Gathers cpu information from each computer listed in -computers.
	.EXAMPLE
		C:\PS> .\Get-CPUInfo.ps1 -file list.txt
		Gathers cpu information from each computer contained in list.txt and displays them in the .Net 3.0 or higher GridView.
	.NOTES
		Name:       Get-CPUInfo.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/02/2010 19:45 CST
#>
param (
	#Computer(s) to query
	#Seperate with a comma (,) for multiple computers
	[array]$computers,

	#File with a list of computers to query
	[string]$file,

	#Run under specified credentials
	[switch]$cred,		

	#Gather all CPU information
	[switch]$full,
	
	#Gather more detailed information, but not full
	[switch]$detailed,
	
	#Display in Grid View
	[switch]$grid
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
	$command = { gwmi win32_processor }
	
	if ($full) { $selection = "*" ; $exclude = "PSComputerName","RunspaceId","PSShowComputerName","_*","CreationClassName"}
	elseif ($detailed) { $selection = "SystemName","MaxClockSpeed","Description","Name","Manufacturer" }
	else { $selection = "SystemName","MaxClockSpeed" } 
	
	#Start the execution of all tasks simultaneously
	#Note again that $sessions contains the credentials, therefore they are not explicitely required for Invoke-Command
	if ($grid) { Invoke-Command -Session $sessions -ScriptBlock $command -ErrorAction SilentlyContinue | select $selection -ExcludeProperty $exclude | Out-GridView }
	else { Invoke-Command -Session $sessions -ScriptBlock $command -ErrorAction SilentlyContinue | select $selection -ExcludeProperty $exclude }
	
	$sessions | Remove-PSSession
}
else { Write-Host "No sessions available.  Please check the computers names you would like to query and try again." }