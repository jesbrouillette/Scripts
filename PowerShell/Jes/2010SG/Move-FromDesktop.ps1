####Event Scenario
#The network team manager complained to the desktop team manager that user profiles are too large and are therefore killing network performance. An investigation has revealed that users are in the habit of downloading pictures, videos, and other large files from the Internet and storing them on their desktops. This habit has created user profiles that are in some cases over one GB in size.
#Your manager has tasked you with writing a script that will move all files from the desktop to a folder such as c:\fso that is not part of the user’s profile. Shortcut files, of course, are not to be moved.
###Design Points
#Your script needs to run only on a local machine.
#The user should be prompted with a message stating which files will be moved and where. The user must agree to the move by clicking Yes.
#The destination folder should be configurable; if the folder does not exist, it should be created.
#Extra design points will be awarded if a selectable file filter mask is implemented. For example, allow the user to select to move .mp3 and .doc files, but not .xls files.
#Style points will be awarded for the presentation of a GUI to select the destination folder.
#Style points will be awarded for the presentation of a progress bar or other visual progress indicator.

[CmdletBinding()]
param (
	#Application to monitor for execution.
	[parameter(Position=0,HelpMessage='Source folder to copy files from.')]
	[string]$source = $env:USERPROFILE + "\Desktop",
	
	#Force logoff without waiting for users to close Office applications.
	[parameter(Position=1,HelpMessage='Destination folder to copy files to.')]
	[string]$destination = "C:\Desktop\" + $env:USERNAME,

	#Force logoff without waiting for users to close Office applications.
	[parameter(Position=2,HelpMessage='Destination folder to copy files to.')]
	[switch]$quiet
)

BEGIN {
	#Function to create a popup message.
	function Create-Notify {
		param(
			[string]$msg,
			[int]$msgTimer
		)
		(New-Object -ComObject Wscript.Shell).popup($msg,$msgTimer,"Information",1)
	}

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
	
	$files = gci $source
	$files | Out-GridView

}

PROCESS {
	$files | Move-Item -Destination $destination
}

END {

}