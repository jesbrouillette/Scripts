<#
	.SYNOPSIS 
		Template used to troublshoot scripting problems.
	.DESCRIPTION
		TroubleShoot-Script.ps1 Template used to troublshoot scripting problems.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays on the console or GUI.
	.EXAMPLE
		C:\PS> .\TroubleShoot-Script.ps1
		Runs TroubleShoot-Script.ps1.
	.NOTES
		Name:       TroubleShoot-Script.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/07/2010 09:35 CST
		Purpose:	2010 Scripting Games: Beginner Event 10--Troubleshooting a Script
#>

#Do not display any errors
$errorActionPreference = "SilentlyContinue"

#Gather the currently logged on user, including domain name, from Win32_ComputerSystem by selecting ONLY the property "UserName"
$wmi = Get-WmiObject -Class Win32_ComputerSystem -Property UserName

#Create the WScript.Shell object which contains a Popup() method for displaying a popup message in the GUI.
$wshShell = New-Object -ComObject wscript.shell

#Display the Popup with the UserName gathered from Win32_ComputerSystem
$wshShell.popup($wmi.UserName)