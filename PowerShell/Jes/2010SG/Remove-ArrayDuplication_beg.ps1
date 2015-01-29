<#
	.SYNOPSIS 
		Add two arrays then remove duplicates and sorts alphabetically.
	.DESCRIPTION
		Remove-ArrayDuplication.ps1 Add two arrays then remove duplicates and sorts alphabetically.
	.PARAMETER array1
		First array.
	.PARAMETER array2
		Second array.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays on the console.
	.EXAMPLE
		C:\PS> .\Remove-ArrayDuplication.ps1
		Calculates then displays the arrays "a","b","c","d" and "d","g","f","e" as:
		a
		b
		c
		d
		e
		f
		g
	.EXAMPLE
		C:\PS> .\Remove-ArrayDuplication.ps1 -array1 "h","e","l","l","o" -array2 "w","o","r","l","d" as:
		d
		e
		h
		l
		o
		r
		w
	.NOTES
		Name:       Remove-ArrayDuplication.ps1
		Author:     Jes Brouillette (ThePosher)
		Last Edit:  05/07/2010 9:15 CST
		Purpose:	2010 Scripting Games: Beginner Event 9--Adding Arrays
#>
param (
	[array]$array1 = @("a","b","c","d"),
	[array]$array2 = @("d","g","f","e")
)

#Add arrays
$array2 | % { $array1 += $_ }

#Display the array sorting alphabetically and only showing unique strings.
$array1 | Sort -Unique