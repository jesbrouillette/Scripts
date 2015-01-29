<#
	.SYNOPSIS 
		Gets process information
	.DESCRIPTION
		Get-Processes.ps1 gathers process information and ads the "Owner" field automatically.  It then displays it to the console.  Any property from Win32_Process can be added to the report by specifying the -prop flag.
	.PARAMETER prop
		Additional properties from Win32_Process to add to the output
	.PARAMETER grid
		Display the output to the GUI as well.
	.PARAMETER file
		Output to a .CSV as well.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays on the console or GUI.
	.EXAMPLE
		C:\PS> .\Get-Processes.ps1
		Shows processes and owner information for all processes on the local computer.
	.EXAMPLE
		C:\PS> .\Get-Processes.ps1 -prop Path -grid
		Adds the Path property to the report and displays the output on console and GUI.
	.NOTES
		Name:       Get-Processes.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/06/2010 11:35 CST
		Purpose:	2010 Scripting Games: Beginner Event 8--Listing Process Information
#>
param (
	[array]$prop, 	#Additional properties from Win32_Process to add to the output
	[switch]$grid,	#Display the output to the GUI as well
	[string]$file	#
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

#Default properties to check.
#The property "Owner" is not directly in the process object, so this must be gather this by using the GetOwner() method of the Process object. 
[array]$properties = "ProcessName",@{ Name="Owner";Expression={($_.GetOwner().Domain + "\" + $_.GetOwner().User)} }
if ($prop) { $prop | % { $properties += $_.ToString() } }

#Gather all processes.
#Select just the columns in the $properties array.
#Sort them by ProcessName and Owner columns and return ONLY the unique processes.
#Create the $processes variable and output to the console.
gwmi win32_process | Select $properties | Sort -unique "ProcessName","Owner" | Tee-Object -Variable processes

#If the -file parameter was set, check for the existance of the file.
if ($file) {
	if (Test-Path $file) {
		
		#Ask before overwriting it if it exists.
		$check = Read-Host "$file already exists.  Do you want to overwrite this?`n(Yes/No)"
	}
	
	#Rough looking calculation takes splits the full path and file name from the -file parameter and trims the file name to return just the path.
	#Then, uses the Create-Folder function above to create the path if it does not exist.
	else { Create-Folder ($file.TrimEnd($file.Split("\")[$file.Split("\").Count-1])) }
	
	#Create the file if it does not exist or if user response was "yes"
	if ($check -match "y" -or !$check) { $processes | Export-Csv $file -NoTypeInformation -Force }
}

#Show the data in a .Net GridView
if ($grid) { $processes | Out-GridView }