<#
	.SYNOPSIS 
		creates files of a given size.
	.DESCRIPTION
		Create-File.ps1 calculates data streams for writing .txt files of any given size.
	.PARAMETER size
		Size of file to create in bytes.  This can be in PowerShells byte conversion format.
		Examples:
		1kb = 1024 bytes
		1mb = 1048576 bytes
	.PARAMETER text
		Custom text to use in the data stream.  The larger this string is the faster the data stream gathering will be.
	.PARAMETER path
		Folder path to store the files.  If this path does not exist it will be created.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays on the console.
	.EXAMPLE
		C:\PS> .\Create-File.ps1
		Creates a 1mb file as C:\CopyTest\TestFile1MB.txt
	.EXAMPLE
		C:\PS> .\Create-File.ps1 -path C:\Temp -size 100mb
		Creates a 100mb file as C:\Temp\TestFile100MB.txt
	.NOTES
		Name:       Create-File.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/02/2010 22:00 CST
		Purpose:	2010 Scripting Games: Advanced Event 8--Creating Text Files of Specific Sizes
#>
param (
	[int]$size = 1mb,				#Size of file to create.  Defaults at 1mb
	[string]$path = "C:\CopyTest",	#Folder for file creation.  Defaults to C:\CopyTest
	[string]$text = "#"				#Text to use for the data stream.  Defaults to "#"
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

#Create the filename based on  the -size parameter.
if (($size % 1kb) -eq 0) { $name = "TestFile" + ($size / 1kb) + "K.txt" ; $byte = "KB" }
if (($size % 1mb) -eq 0) { $name = "TestFile" + ($size / 1mb) + "M.txt" ; $byte = "MB" }
if (($size % 1gb) -eq 0) { $name = "TestFile" + ($size / 1gb) + "G.txt" ; $byte = "GB" }

#Create the folder structure using the Create-Folder function above.
Create-Folder $path

#String value of the full file name.
$file = $path + "\" + $name

#Delete the file if it already exists.
if (Test-Path $file) { Remove-Item $file -Force }

#Make sure the variables used to create the files are empty already.
#If they are not empty the calculations below will not work and the files will be of the wrong size.
$kb = ""
$mb = ""

#Calculate the number of itirations that must be completed to reach the size limit needed.
#The calculations require the division to be rounded up to the next whole number.
#If not, the file will be too small.
#If it is to large we will truncate the text later.
$length = (1kb / $text.Length) + 1

#Files of less than 1mb have different size calculations as the file system handles these a bit differently.
#Making two different data calculations allows for the files to be of EXACT size.
#Instead of writing small bits of data over and over thousands of times, the script creates a a variable of exactly 1kb, then writes this a calculated number of times.
	
#Calculate the 1kb text.
(1..$length) | % { $kb += $text }

#Files smaller than 1mb
if ($size -lt 1mb) {
	Write-Host "Writing $($size/1mb)$byte size file"

	#Calculate the number of itirations.
	(1..($size/1kb))  | % {
	
		#Remove text in the text stream to bring the string length to 1023 chars dynamicaly.
		#Write this text stream to the file.
		$kb.Remove((1kb - 2),($kb.Length - 1kb + 2)) | Out-File $file -Encoding ASCII -Append
	}
}

#Files 1mb or larger
elseif ($size -ge 1mb) {
	(1..1kb) | % { $mb += $kb }
	Write-Host "Writing $($size/1mb)$byte size file"
	(1..($size/1mb)) | % {
	
		#Remove text in the text stream to bring the string length to 1023 chars dynamicaly.
		#Write this text stream to the file.
		$mb.Remove((1mb - 2),($mb.Length - 1mb + 2)) | Out-File $file -Encoding ASCII -Append
	}
}