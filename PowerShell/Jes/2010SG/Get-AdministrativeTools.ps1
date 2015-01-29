<#
	.SYNOPSIS 
		Gathers the names of the installed Administrative Tools
	
	.DESCRIPTION
		Gathers the names of the installed Administrative Tools as reported in Shell.Application and displays within the console.  This can ONLY be run from the console.
	
	.INPUTS
		None.
	
	.OUTPUTS
		None.  Only displays values to the console.
	
	.EXAMPLE
		PoSh:\> .\Get-AdministrativeTools.ps1
		Displays installed Administrative Tools to the console.
	
	.NOTES
		Name:       Get-AdministrativeTools.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/04/2010 17:00 CST
		Purpose:	2010 Scripting Games: Beginner Event 7--Displaying Names of Installed Administrative Tools
#>

#Validate that this is on the console only.
if ($host.Name -notmatch "ConsoleHost") {
	Write-Host ".\Get-AdminTools.ps1 cannot be run from"$Host.Name"`nPlease run the script in a console session."
}
else {
	
	#Administrative Tools are easiest to access from the 47th Namespace within Shell.Application COM object.
	$apps = (New-Object -ComObject "Shell.Application").NameSpace(47).Items() | % { $_.Name }
	Clear-Host

#Using the Here-String constructor simply to make the script easier to read
@"
Installed Administrative Tools:
===============================================================================
"@
$apps
@"
===============================================================================
$($apps.Count) Administrative Tools installed.

"@
}