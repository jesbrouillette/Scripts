<#
	.SYNOPSIS 
		Adds tags for a given server instance.
	.DESCRIPTION
		Adds tags for a given server instance within the RS Dashboard.
	.INPUTS
		Piped objects are not accepted.
	.OUTPUTS
		Displays in the RightScale Dashboard only.
	.NOTES
		Name:       Add-RSTag.ps1
		Author:     Jes Brouillette - RightScale
		Last Edit:  11/13/2013 13:30 CST
		Purpose:	Adds tags for a given server instance within the RS Dashboard.
#>

#==== Start: Script Variables ================================================#

$Tags = $ENV:CREATE_TAGS.Split(",")

# == Retrieve existing tags == #
$OldTags = rs_tag --list  | ? { $_ -notmatch "\[|\]" } | % { $_ -replace "^\s\s|[`",]","" }

# == Compare existing tags to new tags and only add tags that do not already exist == #
$Tags | ? {
	$OldTags -notcontains $_
} | % {
	Write-Host "Adding $_"
	Invoke-Expression "rs_tag --add `"$_`""
}

# == Retrieve new tags == #
$NewTags = rs_tag --list | ? { $_ -notmatch "\[|\]" } | % { $_ -replace "^\s\s|[`",]","" }

# == Compare new tags and validate creation of valid tags  == #
$NotSet = $Tags | ? { $NewTags -notcontains $_ }

#==== Finish =================================================================#

if ($NotSet -ne $Null) { $NotSet | % { Write-Host "Unable to set tag:  $_" }
else { Write-Host "All tags set successfully" }