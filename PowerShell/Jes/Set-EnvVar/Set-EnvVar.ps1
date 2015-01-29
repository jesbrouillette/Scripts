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
	[string]$name,		#Variable name
	[string]$value,		#Variable value
	[switch]$user,		#Create the variable in the User space
	[switch]$system,	#Create the variable in the System space
	[array]$computers,	#Remote computer(s) to create the variable in.  Seperate with a comma (,) for multiple computers.
	[string]$file,		#File with a list of computers to create the variable in
	[switch]$cred,		#Run under specified credentials
	[switch]$quiet,		#Silent
	[switch]$help		#Display help information
)

#Check for existence and value of the variable
function Check-EnvVar ($name,$value,$type) {

	#Creates the command to execute on the remote session
	$command = {
		param (
			$name,
			$value,
			$type
		)
		#Create a new object with required information to return back from the function
		New-Object PSObject -Property @{
			Computer = $env:COMPUTERNAME
			Name = $name
			Value = ([System.Environment]::GetEnvironmentVariable($name,$type))
		}
	}
	
	#Execute the command
	if ($credentials) { Invoke-Command -Session $sessions -ScriptBlock $command -ArgumentList $name,$value,$type -ErrorAction SilentlyContinue -Credential $credentials }
	else { Invoke-Command -Session $sessions -ScriptBlock $command -ArgumentList $name,$value,$type -ErrorAction SilentlyContinue }
}

#Create the variable if it does not exist, or set the value if it does
function Create-EnvVar ($name,$value,$type) {

	#Creates the command to execute on the remote session
	$command = {
		param (
			$name,
			$value,
			$type
		)
		[System.Environment]::SetEnvironmentVariable($name,$value,$type)

		#Create a new object with required information to return back from the function
		New-Object PSObject -Property @{
			Computer = $env:COMPUTERNAME
			Date = (Get-Date).ToString()
			Result = if ($Error) {$error[0].Exception.Message ; $error.Clear()} else {"Success"}
		}
	}
	
	#Execute the command
	if ($credentials) { Invoke-Command -Session $sessions -ScriptBlock $command -ArgumentList $name,$value,$type -ErrorAction SilentlyContinue -Credential $credentials }
	else { Invoke-Command -Session $sessions -ScriptBlock $command -ArgumentList $name,$value,$type -ErrorAction SilentlyContinue -Credential $credentials }
}

#Validate all required user input before beginning execution
if ($user -and $system) { "You may only select -System or -User, not both" ; Exit }
elseif ($user) { $type = "User" }
elseif ($system) { $type = "Machine" }
else { "You must select -System or -User" ; Exit }

if (!$name) { $name = Read-Host "Please input the Name of the environment variable you wish to create." }
if (!$value) { $value = Read-Host "Please input the Value of the environment variable you wish to create." }

if ($file) { $sessions = nsn (gc $file) }
elseif ($computers) { $sessions = $computers | % { nsn -ComputerName $_ } }
else { $sessions = nsn -ComputerName . }

if ($cred) { $credentials = Get-Credential }

#Check for existence and value of the variable using the Check-EnvVar function
$check = Check-EnvVar $name $value $type | % {
	
	#Ask for user input if the variable already exists, or bypass if the -Quiet switch is enabled or the variable does not exist.
	if (!$quiet -and $_.Value) {
		Read-Host ("`n" + $_.Computer + "`n" + $_.Name + "=" + $_.Value + "`nDo you want to overwrite this entry.`n(Yes/No)") | % {
			if ($_ -match "y") { $change = $true }
			else { $change = $false }
		}
	}
	else { $change = $true }
	
	#Create a new object with required information to enter into $check
	New-Object PSObject -Property @{
		Computer = $_.Computer
		Change = $change
		Value = $_.Value
	}
}

#Remove any sessions on which the variable will not be changed if .Change is not $true.
$check | ? {$_.Change -ne $true} | % {
	if ($env:COMPUTERNAME -match $_.Computer) { Remove-PSSession -ComputerName "localhost" }
	else { Remove-PSSession -ComputerName $_.Computer }
	$sessions = Get-PSSession
}

#If there are any remainging sessions created by the script, execute the change.
if ($sessions) {
	$create = Create-EnvVar $name $value $type | Select Computer,Result,Date
	$sessions | Remove-PSSession
}

#If not, create a log noting no remaining sessions.
else {
	New-Object PSObject -Property @{
		Computer = "none"
		Date = (Get-Date).ToString()
		Result = "all computers have been removed from the change list."
	} | Select Computer,Result,Date | Export-Csv "Set-EnvVar_Log.csv" -NoTypeInformation
}

#Merge the checked list with the change list for a unified log
if ($check) {
	$check | % {
		$checked = $_
		$create | ? { $checked.Computer -eq $_.Computer } | % {
			
			#Create a new object with required information for the final log
			New-Object PSObject -Property @{
				Computer = $checked.Computer
				Variable = $name
				PreviousValue = $checked.Value
				NewValue = $value
				Result = $_.Result
				Date = $_.Date
			}
		}
	
	#Creates the final log
	} | Select Computer,Variable,PreviousValue,NewValue,Result,Date | Export-Csv "Set-EnvVar_Log.csv" -NoTypeInformation
}

#Log errors
if ($error) {
	$error | % {
		$_ | Out-File "Set-EnvVar_errors.log" -Append
	}
	"Errors were reported.  Please check Set-EnvVar_errors.log"
	$error.Clear()
}