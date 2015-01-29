################################################################################
#                                                                              #
# Purpose:                                                                     #
#     Sets permissions based on a csv formatted file.                          #
#                                                                              #
# Execution:                                                                   #
#     Utilizing .NET ACLS's are removed for the given groups, then added       #
#     in with their access levels being set according to information input     #
#     into a .csv file.                                                        #
#                                                                              #
# Usage:                                                                       #
#     \Set-Permissions.ps1 filename (/h|/?)                                    #
#                                                                              #
# Switches:                                                                    #
#     /h - displays help                                                       #
#     /? - same as /h                                                          #
#                                                                              #
# Example:                                                                     #
#     .\Set-Permissions.ps1 c:\temp\perms.csv                                  #
#     Sets permisions accoridng the the settings in c:\temp\perms.csv          #
#	                                                                           #
# CSV Format:                                                                  #
#     Share,Group,Access                                                       #
#     ["sharename"],[groupname],[accesslevel]                                  #
#                                                                              #
#     Where:                                                                   #
#         [sharename] is the full path to the folder                           #
#         [groupname] is the full Active Directory Group Name                  #
#         [accesslevel] is `"Modify`" or `"Read-Only`"                         #
#                                                                              #
################################################################################

#$erroractionpreference = "SilentlyContinue"

$strArgs = [string]$args

#Help section
if ($strArgs.ToLower() -match "/h" -or $strArgs.ToLower() -match "\?" -or $strArgs.ToLower() -eq "") {
	$strHelp = "Set-Permissions.ps1`n  Sets permissions based on a csv formatted file.`n`nUsage:`n.  \Set-Permissions.ps1 filename (/h|/?)`n`nSwitches:`n  /h - displays this message`n  /? - same as /h`n`n`nExamples:`n  .\Set-Permissions.ps1 c:\temp\perms.csv`n  Sets permisions accoridng the the settings in c:\temp\perms.csv`n`nCSV Format:`n  Share,Group,Access`n  [sharename],[groupname],[accesslevel]`n  Where:`n    [sharename] is the full path to the folder`n    [groupname] is the full Active Directory Group Name`n    [accesslevel] is `"Modify`" or `"Read-Only`"`n"
	$objMsgBox = new-object -comobject wscript.shell
	$objMsgBox.Popup($strHelp,0,"Set-Permissions.ps1")
	exit
}

#Imports the csv file into a PowerShell table
$objImport = Import-Csv $args[0]
$strDomain = $args[1]

#Setting for Inheritance to inherit the parent folder
#Setting Propigation to propigate to all child folders
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"

#The heart of the script
function SetACL ($strGroupF,$strShareF,$strAccessF) {
	#Removes all ACL's for the current group
	$objACL = Get-Acl $strShareF
	$objAccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($strGroupF,"FullControl",$inherit, $propagation,"Allow")
	$objACL.RemoveAccessRuleAll($objAccessRule)
	Set-Acl $strShareF $objACL

	#Sets the appropriate ACL's for the current group
	$objACL = Get-Acl $strShareF
	$objAccessRule = New-Object system.security.accesscontrol.filesystemaccessrule($strGroupF,$strAccessF,$inherit, $propagation,"Allow")
	$objACL.addAccessRule($objAccessRule)
	Set-Acl $strShareF $objACL
}

#Inputs the information into the the SetACL function for all Modify groups
write-output $objImport | where {$_.Access -eq "Modify"} | foreach {
	$strGroup = $strDomain + "\" + $_.Group
	$strShare = $_.Share
	SetACL $strGroup $strShare "Modify"
}

#Inputs the information into the the SetACL function for all Read-Only groups
write-output $objImport | where {$_.Access -eq "Read-Only"} | foreach {
	if ($_.Group -like "CORP*") {
		$strGroup = $_.Group
	}
	Else {
		$strGroup = $strDomain + "\" + $_.Group
	}
	$strShare = $_.Share
	SetACL $strGroup $strShare "ReadAndExecute"
}