<#
	.SYNOPSIS 
		Sets remote and local environment variables
	
	.DESCRIPTION
		Create-ClassNotes.ps1 creates .txt files for taking notes in class using a template form.
		
		It utilizes a default set of classes, but also takes custom classes based on an array input.  The note files are named by the date of the 1st Monday following the date given and incorporating the class name.
		
		Default class names are saved into the registry upon first run and are pulled from their each subsequent run.  Thease are overwritable using either the -add or -classes switches (see get-help .\Create-ClassNotes.ps1 -full for more information)
		
		Input is allowed with named properties from the pipe.
	
	.PARAMETER date
		Specify the week for generating class notes files.  Mandetory value.
		The class notes date will be calculated to the next Monday from this date.
	
	.PARAMETER add
		Additional class names for generating notes files.
	
	.PARAMETER browse
		Use GUI interface to select the location of the files created.
	
	.PARAMETER default
		Sets the current class array into the registry as the default value.  This will include all class names during this run instance.
	
	.PARAMETER restore
		Restores the registry setting to its original default value
	
	.PARAMETER classes
		Class names for generating notes files in an Array format.  The default values are not used.  This will not get saved as the default unless -default is chosen.
	
	.PARAMETER path
		Folder location to save the class notes files.  If not selected "C:\ClassNotes\" will be used.
	
	.PARAMETER weeks
		Specify the number of weeks for generating class notes files.
	
	.PARAMETER help
		Display help information.
	
	.INPUTS
		Create-ClassNotes.ps1 accepts named properties from the pipe.
	
	.OUTPUTS
		Create-ClassNotes.ps1 outputs multiple files as specified by the -path, -date, and -classes variables.
	
	.EXAMPLE
		PoSh:\> .\Create-ClassNotes.ps1 -date 05/15/2015 -weeks 2
		Two weeks of class notes files will be generated from the Monday following the date given.  Notes files will be stored in the default folder "C:\ClassNotes"
	
	.EXAMPLE
		PoSh:\> .\Create-ClassNotes.ps1 -classes "Applied Hydrodynamics","Modern Medicine" -browse
		Class notes will be generated for "Applied Hydrodynamics" and "Modern Medicine" in a folder chosen by the user through the GUI.
	
	.EXAMPLE
	
		PoSh:\> Get-Date | .\Create-ClassNotes.ps1
		Class notes will be generated based on the default class names and the current date.  [System.DateTime] is passed throught the pipe from Get-Date.
	
	.NOTES
		Name:       Create-ClassNotes.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/03/2010 17:45 CST
		Purpose:	2010 Scripting Games: Advanced Event 3--Creating Text Files for Class Note-Taking
#>
param (
	[parameter(	Mandatory=$True,Position=0,ValueFromPipelineByPropertyName=$true)]
	[datetime]$date,
	
	[parameter(Mandatory=$False,Position=1,ValueFromPipelineByPropertyName=$true)]
	[switch]$add,
	
	[parameter(Mandatory=$False,Position=2,ValueFromPipelineByPropertyName=$true)]
	[switch]$browse,
	
	[parameter(Mandatory=$False,Position=3,ValueFromPipelineByPropertyName=$true)]
	[switch]$default,
	
	[parameter(Mandatory=$False,Position=4,ValueFromPipelineByPropertyName=$true)]
	[switch]$restore,
	
	[parameter(Mandatory=$False,Position=5,ValueFromPipelineByPropertyName=$true)]
	[array]$classes,
	
	[parameter(Mandatory=$False,Position=6,ValueFromPipelineByPropertyName=$true)]
	[string]$path = "C:\ClassNotes\",

	[parameter(Mandatory=$False,Position=7,ValueFromPipelineByPropertyName=$true)]
	[int]$weeks = 1
)

#Creates the folder structure for the specified save path.
#The last folder name is trimmed off by splitting at the backslasy (\) then trimming the characters of the last split object.
function Create-Folder {
	param (
		[string]$folder
	)
	$split = $folder.split("\")
	$parent = $folder.TrimEnd(($split[$split.Count-1]+"\"))
	
	#Test for the existance of the parent folder.
	#Send the parent back through this function if it does not exist.
	#Create the tail folder if it does.
	if (!(Test-Path $parent)) { Create-Folder $parent }
	if (!(Test-Path $folder)) { New-Item -ItemType Directory $folder -ErrorAction SilentlyContinue | Out-Null }
}

#Calculates to the next coming Monday, or leaves the existing date if it is already a Monday
function Calculate-Weeks {
	param (
		[datetime]$date,
		[int]$weeks
	)
	switch ($date.DayofWeek) {
		Sunday { $date = $date.AddDays(1) }
		Monday { $date = $date.AddDays(0) }
		Tuesday { $date = $date.AddDays(6) }
		Wednesday { $date = $date.AddDays(5) }
		Thursday { $date = $date.AddDays(4) }
		Friday { $date = $date.AddDays(3) }
		Saturday { $date = $date.AddDays(2) }
	}
	(0..($weeks-1)) | % { $date.AddDays($_*7) }
}

#Createts the files with content based on the class name and date input.
#Files are created in the path specified.
#File names and content are calculated from the Calculate-Weeks function.
function Create-Files {
	param (
		[string]$class,
		[string]$path,
		[datetime]$date,
		[int]$weeks
	)
	Calculate-Weeks $date $weeks | % {
		Get-Date $_ -Format MM_dd_yyyy | % {
			$file = $path + "\" + $_ + "-" + $class + ".txt"

#Utilizing the Here-String construction allows for betting viewing in the script of the files content structure.
@"
CLASS: $($class)
DATE: $($_.Replace("_","/"))
NOTES:
"@ | % {
				$_ | Out-File $file -Encoding ASCII
			}
		}
	}
}

#In order to not create registry problems, the script does NOT accept a custom registry key location.
#Location in the registry
$regpath = "HKLM:\Software\ClassNotes"
#MultiString name
$regname = "Classes"

#Create Directory structure
#Allow the user to select an existing folder from the GUI, or uses the $path variable from the command line.
if ($browse) { $path = ((New-Object -ComObject Shell.Application).BrowseForFolder(0,"Class Notes Folder:",0)).Self.Path }
else { Create-Folder $path }

#Checks for the existance of the proper registry keys and creates them with the default values if the do not exist.
#$first run is flagged as $false to skip overwriting existing classes.
if (Test-Path $regpath) {	
	$firstRun = $false
	if (!$classes) { $classes = (Get-ItemProperty $regpath).Classes }
}
#$first run is flagged as $true to allow the script to create all necessary registry entries.
else {
	$firstRun = $true
	Create-Folder $regpath
}

#Restores or creates the default content for the $class array.
if ($restore -or $firstRun) {
	if ($classes) { $classes | % { Create-Files $_ $path $date $weeks } }
	$classes = "Shakespeare","World Literature","Calculus 2","Physics","Music Appreciation","American Literature Since 1850"
}

#Import existing registry values into the current array when -add was specified
if ( $add ) { (Get-ItemProperty $regpath).Classes | ? { $classes -notcontains $_ } | % { $classes += $_ } }

#Creates files with content using the Create-Files function from above - yup.
if (!$firstrun) { $classes | % { Create-Files $_ $path $date $weeks } }

#Creates new registry values when specified.
if ($default -or $firstRun -or $restore) { New-ItemProperty -Path $regpath -Name $regname -Value $classes -PropertyType multistring -Force | Out-Null }