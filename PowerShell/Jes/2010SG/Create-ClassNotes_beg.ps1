<#
	.SYNOPSIS 
		Creates file for taking notes.
	.DESCRIPTION
		Create-ClassNotes.ps1 creates template note files.
	.PARAMETER path
		Folder location to save files.
	.PARAMETER start
		File number to start.
	.PARAMETER end
		File number to end.
	.PARAMETER files
		Number of files to create
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		File##.txt.
	.EXAMPLE
		C:\PS> .\Create-ClassNotes.ps1
		Create 10 files in the default directory (C:\ClassNotes).
	.EXAMPLE
		C:\PS> .\Create-ClassNotes.ps1 -files 4
		Create 4 files in the default directory (C:\ClassNotes).
	.EXAMPLE
		C:\PS> .\Create-ClassNotes.ps1 -start 3 -end 18
		Create files in the default directory (C:\ClassNotes) starting with 3 and ending with 18.
	.NOTES
		Name:       Create-ClassNotes.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/05/2010 11:15 CST
		Purpose:	2010 Scripting Games: Beginner Event 3--Creating Text Files for Class Note-Taking
#>
param (
	[string]$path = "C:\ClassNotes",	#Folder location to save files.
	[int]$start = 1,					#File number to start.
	[int]$end = 10,						#File number to end.
	[int]$files							#Number of files to create
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

#Create the folder path if it does not exist.
Create-Folder $path

#Create the number for ending files.
if ($files) { $end = $start + $files }

#Count
(0..10) | % { Set-Content -Path $($path + "\File" + $_ + ".txt") -Value $("CLASS:","DATE:","NOTES:") }