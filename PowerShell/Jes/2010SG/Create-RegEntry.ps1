<#
	.SYNOPSIS 
		Creates a registry entry
	
	.DESCRIPTION
		Create-RegItem.ps1 creates a registry entry.  When run without any arguements it will create a REG_SZ named "LastUpdated" with the current date in HKCU:\Software\ScriptingGuys\2010ScriptingGames.
	
	.PARAMETER date
		Specify the week for generating class notes files.  Mandetory value.

	.PARAMETER path
		Registry key under which to create the entry.
	
	.PARAMETER name
		Registry entry name.
	
	.PARAMETER value
		Registry entry value.
		
	.PARAMETER type
		Registry entry type.  Available Types:
		
		String (REG_SZ)              - Creates a string 
		ExpandString (REG_EXPAND_SZ) - A string with environment variables that are resolved when invoked
		Binary (REG_BINARY)          - Binary values 		
		DWord (REG_DWORD)            - Numeric values 		
		MultiString (REG_MULTI_SZ)   - Text of several lines
		QWord (REG_QWORD)            - 64-bit numeric values 
	
	.INPUTS
		Accepts named properties from the pipe.
	
	.OUTPUTS
		None.  Only creates the registry entry.
	
	.EXAMPLE
		PoSh:\> .\Create-RegItem.ps1
		Creates a REG_SZ named "LastUpdated" with the current date in HKCU:\Software\ScriptingGuys\2010ScriptingGames.
	
	.NOTES
		Name:       Create-RegItem.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/04/2010 10:45 CST
		Purpose:	2010 Scripting Games: Beginner Event 1--Updating and Creating Registry Keys
#>
param (
	[parameter(	Position=0,ValueFromPipelineByPropertyName=$true)]
	[string]$path = "HKCU:\Software\ScriptingGuys\2010ScriptingGames",
	
	[parameter(	Position=1,ValueFromPipelineByPropertyName=$true)]
	[string]$name = "LastUpdated",
	
	[parameter(	Position=2,ValueFromPipelineByPropertyName=$true)]
	[string]$value = (Get-Date -Format G),

	[parameter(	Position=3,ValueFromPipelineByPropertyName=$true)]
	[string]$type = "String"
)

#Reverse check and creation of a folder or registry structure.
function Create-Folder {
	param (
		[string]$folder
	)
	$split = $folder.split("\")
	$parent = $folder.TrimEnd(($split[$split.Count-1]))
	
	#Test for the existance of the parent folder.
	#Send the parent back through this function if it does not exist.
	#Create the tail folder if it does.
	if (!(Test-Path $parent)) { rv split ; Create-Folder $parent.TrimEnd("\") }
	if (!(Test-Path $folder)) { New-Item -ItemType Directory $folder | Out-Null }
}

#Create the folder structure.
Create-Folder $path

#Create the registry entry.
New-ItemProperty -Path $path -Name $name -Value $value -PropertyType $type -Force | Out-Null