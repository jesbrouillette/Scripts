param (
	[string] $CSV, #file to import (optional - you will be prompted if not specified)
	[switch] $Help, #Displays the help message
	[switch] $Show, #exports all groups and all settings to .csv files
	[switch] $Remove, #removes existing folder security before starting
	[switch] $Managed #Does not set "manager can update membership list"
)

################################################################################
#                                                                              #
#  Secure-Folders.ps1                                                          #
#  Written By:  Jes Brouillette (jes_brouillette@cargill.com                   #
#  Last Modified:  06/11/09                                                    #
#                                                                              #
#  ==========================================================================  #
#                                                                              #
#               WARNING: THIS SCRIPT CAN TAKE SEVERAL HOURS TO                 #
#                  REPLACE PERMISSIONS ON FOLDERS.  CLOSING                    #
#                    BEFORE THE SCRIPT FINISHED CAN CAUSE                      #
#                          FOLDER PERMISSION ERRORS                            #
#                                                                              #
#                 DO NOT USE FOR CREATING FOLDERS IN CLUSTERS.                 #
#                     THIS IS FOR STAND-ALONE SERVERS ONLY                     #
#                                                                              #
#  ==========================================================================  #
#                                                                              #
#  Note:                                                                       #
#     For best performance run from a machine on a network local to the server #
#     where the shares and a Domain Controller reside                          #
#                                                                              #
#  Purpose:                                                                    #
#    Secures folders according to the F&P standards as of Nov 2008.  This      #
#    script will only create what has been specified in the .csv file.  You    #
#    MUST validate the folder structure before running this script.  Please    #
#    refrer to the MWTS KB for details:                                        #
#    http://sharepoint.hosting.cargill.com/GHSKB/Forms/Default.aspx?RootFolder=%2fGHSKB%2fProcesses%2c%20Procedures%20and%20Decision%20Trees%2fMWTS%2fStandards%2fFile%20and%20Print&FolderCTID=0x0120000EE4023FBA876F4088B5F875FE5E904C&View=%7b56455794%2d47E5%2d472B%2d9085%2d140D93CE2358%7d
#                                                                              #
#  Execution:                                                                  #
#     1.)  Gathers information from the csv file selected                      #
#     2.)  Creates AD User Group                                               #
#     3.)  Creates the folders, if they need created                           #
#     4.)  Adds the proper AD Security Group and settings for each folder      #
#     5.)  Adds users to the proper AD Security Group                          #
#                                                                              #
#  Switches:                                                                   #
#     -help - Displays the help message                                        #
#     -csv - file to import (optional - you will be prompted if not specified) #
#     -show - exports all groups and all settings to .csv files                #
#     -remove - removes existing folder security before starting               #
#                                                                              #
#  Usage:                                                                      #
#     .\Secure-Folder.ps1 (-help, -csv, -show, -remove)                        #
#                                                                              #
#  CSV File Format:                                                            #
#     share,groupou,approve,modify,read                                        #
#     [share],[groupou],[approver(s)],[modify_users],[read-only_users]         #
#                                                                              #
#     Where:                                                                   #
#         [share] = the full path to the folder                                #
#         [groupou] = the full LDAP path where the group will be created       #
#         (MUST be in Quotes if created in Notepad)                            #
#         [approver(s)] = approvers in the format [domain]\[username]          #
#         [modify_users] = modify users in the format [domain]\[username]      #
#         [read-only_users] = read-only users in the format [domain]\[username]#
#                                                                              #
# **For multiple users in each group, use a semicolon (;) to sepearate users** #
#                                                                              #
#  ==========================================================================  #
#                                                                              #
#	Planned Functionality:                                                     #
#		1.)  Import into Approvers DB                                          #
#		2.)  Switches                                                          #
#			A.) -Folders - Create Folders only                                 #
#			B.) -Groups - Create Groups only                                   #
#			C.) -Approvers - Set Approvers only                                #
#			D.) -UnManaged - Does not set "Managed By"                         #
#			E.) -Members - Set Members only                                    #
#			F.) -Import - Import Into Approvers DB only                        #
#			G.) -Secure - Secure Folders only                                  #
#                                                                              #
################################################################################

$erroractionpreference = "Continue"

$PauseTime = 10 # how long to wait for AD to save groups
$LogDate = Get-Date -format "MM-dd-yy.HH.mm.ss"
$LogFile = "Secure-Folder " + $LogDate + ".log"
$LogArray = New-Object System.Collections.ArrayList
$MsgBox = new-object -comobject wscript.shell

if ($help) { #Displays help
	$HelpMsg = "                                                                              
             WARNING: THIS SCRIPT CAN TAKE SEVERAL HOURS TO
                   REPLACE PERMISSIONS ON FOLDERS.  CLOSING
                       BEFORE THE SCRIPT FINISHED CAN CAUSE
                                   FOLDER PERMISSION ERRORS
								   
               DO NOT USE FOR CREATING FOLDERS IN CLUSTERS.
                       THIS IS FOR STAND-ALONE SERVERS ONLY
 
==============================================

Note:                                                                       
   For best performance run from a machine on a network local to the server 
   where the shares and a Domain Controller reside                          

Purpose:                                                                    
  Secures folders according to the F&P standards as of Nov 2008.  This
  script will only create what has been specified in the .csv file.  You
  MUST validate the folder structure before running this script.  Please
  refrer to the MWTS KB for details.

Execution:                                                                  
   1.)  Gathers information from the csv file selected                      
   2.)  Creates AD User Group                                               
   3.)  Creates the folders, if they need created                           
   4.)  Adds the proper AD Security Group and settings for each folder      
   5.)  Adds users to the proper AD Security Group                          

Usage:                                                                      
   .\Secure-Folder.ps1 (-help, -csv, -show, -remove)

Switches:
   -help - Displays this message
   -csv - file to import (optional - you will be prompted if not specified)
   -remove - removes existing folder security before starting
   -show - exports all groups and all settings to .csv files

CSV File Format:                                                            
   share,groupou,approve,modify,read                                        
   [share],[groupou],[approver(s)],[modify_users],[read-only_users]         

   Where:                                                                   
       [share] = the full path to the folder                                
       [groupou] = the full LDAP path where the group will be created       
       (MUST be in Quotes if created in Notepad)                            
       [approver(s)] = approvers in the format [domain]\[username]          
       [modify_users] = modify users in the format [domain]\[username]      
       [read-only_users] = read-only users in the format [domain]\[username]

**For multiple users in each group, use a semicolon (;) to sepearate users**"

	$MsgBox.Popup($HelpMsg,0,"Secure-Folder.ps1") | Out-Null
	exit
}

$PopupMsg = "Folders must not contain comma's or apostrophe's.`n`t Does your list contain these?"
$Popup = $MsgBox.Popup($PopupMsg,0,"Secure-Folders.ps1",4)

if ($Popup -eq 6) {
	$Popup = $MsgBox.Popup("Please remove or rename the folders  `n      with commas (,) apostrophies (') or parenthasies (())",0,"Secure-Folders.ps1",0)
	exit
}

#  Define-Functions start  #

function Write-Logs ($LogTxtF,$ErrorF) {
	$now1 = Get-Date -uFormat %x
	$now2 = Get-Date -Format T
	$now = $now1 + " " + $now2 + ":"
	
	if ($ErrorF) {
		$ErrMsg = $ErrorF[0].Exception.Message
		if ($ErrMsg -like "*already exists*") {
			$LogArray.Add("$now  $LogTxtF it already exists") | Out-Null
		}
		else {
			$LogArray.Add("$now  ERROR:  $LogTxtF $ErrMsg") | Out-Null
		}
	}
	else {
		$LogArray.Add("$now  $LogTxtF") | Out-Null
	}	
	$error.Clear()
}

function Get-DN ($SAMNameF,$ClassTypeF,$LDAPPathF) { # function retuns the full CN of the user or group
	$ADSIRoot = [ADSI]("LDAP://$LDAPPathF")
	$ADSearch = new-object System.DirectoryServices.DirectorySearcher
	$ADSearch.SearchRoot = $ADSIRoot
	$ADSearch.Filter = "(&(objectCategory=$ClassTypeF)(sAMAccountName=$SAMNameF))"
	$FoundUsers = $ADSearch.findall()
	$FoundUsers[0].path
} # end Get-DN function

function AD-Pause ($PauseTimeF) { # Pauses until the first AD Group has been successfully stored.
	$CountUp = 0
	do {
		Start-Sleep -Seconds $PauseTimeF
		$Group = $FullTable.Rows[0].Group
		$Domain = Reverse-ADSI $FullTable.Rows[0].GroupOU
		$ClassType = "group"
		$GroupADSI = Set-ADSI $Domain # set the domain path for the group
		$GroupPath = Get-DN $Group $ClassType $GroupADSI # find the full LDAP path for the group account
		$ADGroup = [ADSI]("$GroupPath")
		$CountUp += $PauseTimeF
	}
	until ($ADGroup -ne $null -or $CountUp -ge 180)
	
	if ($CountUp -eq 180) {
		Write-Logs "AD Groups are not storing properly.`nSecure-Folders.ps1 Exiting"
		exit
	}
	else {
		Write-Logs "AD Groups stored properly"
	}
}

function Set-ACLs ($GroupF,$ShareF,$AccessTypeF) { # Sets the folder security
	Write-Logs ("Adding " + $GroupF + " to " + $ShareF)
	if ($remove) {
		# Removes all ACL's for the current group if they have access already
		$ACL = Get-Acl $ShareF
		foreach ($ACLAccess in $ACL.Access) {
			$AccessIDRef = $ACLAccess.IdentityReference
			if ($AccessIDRef -eq $GroupF) {
				$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($GroupF,"FullControl",$inherit, $propagation,"Allow")
				$ACL.RemoveAccessRuleAll($AccessRule) | Out-Null
				Set-Acl $ShareF $ACL
				if ($error) { 
					Write-Logs ($GroupF + " was not removed from " + $ShareF + ":") $error
					$ErrNumb += 1
				}
				else { 
					Write-Logs ($GroupF + " was removed from " + $ShareF)
				}
			}
		}
	}

	# Sets the appropriate ACL's for the current group
	$ACL = Get-Acl $ShareF
	$AccessRule = New-Object System.Security.Accesscontrol.FileSystemAccessRule($GroupF,$AccessTypeF,$inherit,$propagation,"Allow")
	$ACL.AddAccessRule($AccessRule) | Out-Null
	Set-Acl $ShareF $ACL
	if ($error) { 
		Write-Logs ($GroupF + " was not added to " + $ShareF + ":") $error
		$ErrNumb += 1
	}
	else { 
		Write-Logs ($GroupF + " was added to " + $ShareF + " with " + $AccessTypeF + " access")
	}
} # end set-acls function

function Set-ADSI ($DomainF) {# sets the correct ADSI container for each domain
	if ($DomainF.ToLower() -eq "ap"){
		return "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($DomainF.ToLower() -eq "eu"){
		return "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($DomainF.ToLower() -eq "la"){
		return "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($DomainF.ToLower() -eq "meat"){
		return "dc=meat,dc=cargill,dc=com"
	}
	elseif ($DomainF.ToLower() -eq "na"){
		return "dc=na,dc=corp,dc=cargill,dc=com"
	}
	else {
		return "dc=corp,dc=cargill,dc=com"
	}
} # end Set-ADSI function

function Reverse-ADSI ($DomainF) { # sets the correct domain for the given adsi path
	if ($DomainF -match "dc=ap") {
		return "ap"
	}
	elseif ($DomainF -match "dc=eu") {
		return "eu"
	}
	elseif ($DomainF -match "dc=la") {
		return "la"
	}
	elseif ($DomainF -match "dc=na") {
		return "na"
	}
	elseif ($DomainF -match "dc=meat") {
		return "meat"
	}
	else {
		return "corp"
	}
} # end Reverse-ADSI function

#  Define-Functions end  #

$begin = Get-Date
Write-Logs "`#===========================================================`#"
Write-Logs " "
Write-Logs ("Script execution begun by " + $env:USERDOMAIN + "\" + $env:USERNAME)
Write-Logs " "

#  Convert-Share start  #

if (!$CSV) {
	[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	$OpenFile = New-Object Windows.Forms.OpenFileDialog
	$OpenFile.Title = "Open - Share Folder Conversion List"
	$OpenFile.Filter = "Comma Seperated Value (*.csv)|*.csv"
	$OpenFile.ShowDialog() | Out-Null
	$Shares = Import-Csv $OpenFile.FileName
 } else {
 	$Shares = Import-Csv $CSV
}

$FullTable = New-Object system.Data.DataTable "Full DataTable" # Setup the Datatable Structure
$TableCol1 = New-Object system.Data.DataColumn Share,([string])
$TableCol2 = New-Object system.Data.DataColumn Group,([string])
$TableCol3 = New-Object system.Data.DataColumn GroupOU,([string])
$TableCol4 = New-Object system.Data.DataColumn Access, ([string])
$TableCol5 = New-Object system.Data.DataColumn UserDom, ([string])
$TableCol6 = New-Object system.Data.DataColumn UserName, ([string])

$FullTable.columns.add($TableCol1) | Out-Null
$FullTable.columns.add($TableCol2) | Out-Null
$FullTable.columns.add($TableCol3) | Out-Null
$FullTable.columns.add($TableCol4) | Out-Null
$FullTable.columns.add($TableCol5) | Out-Null
$FullTable.columns.add($TableCol6) | Out-Null

Write-Host "Converting Shares to Tables"
Write-Host "  Creating the FullDataTable"

foreach ($Share in $Shares) {
	$SharePath = $Share.share
	$Group = $SharePath.ToLower() -replace "\\","~" -replace " ","_" -replace "~~","" -replace "data","" -replace ",","" -replace "'",""
	$GroupA = $Group + "~a"
	$GroupM = $Group + "~m"
	$GroupOU = $Share.GroupOU
			
	# approvers
	$UserName = $Share.Approve
	if ($UserName.Length -gt 0) {
		foreach ($Approvers in $UserName) {
			if ($Approvers -like "*;*") {
				$UserSplit = $Approvers.Split(',;')
			}
			else {
				$UserSplit = $Approvers
			}
			foreach ($User in $UserSplit) {
				$TableRow = $FullTable.NewRow()
				$TableRow.Share = $SharePath -replace "`"",""
				$TableRow.Group = $GroupA
				$TableRow.GroupOU = $GroupOU
				$TableRow.Access = "Approver"
				$TableRow.UserDom = Split-Path $User -parent
				$TableRow.UserName = Split-Path $User -leaf
				$FullTable.Rows.Add($TableRow) | Out-Null
			}
		}
	}

	# modify
	$UserName = $Share.Modify
	if ($UserName.Length -gt 0) {
		foreach ($ModifyUsers in $UserName) {
			if ($ModifyUsers -like "*;*") {
				$UserSplit = $ModifyUsers.Split(',;')
			}
			else {
				$UserSplit = $ModifyUsers
			}
			foreach ($User in $UserSplit) {
				$TableRow = $FullTable.NewRow()
				$TableRow.Share = $SharePath -replace "`"",""
				$TableRow.Group = $GroupM
				$TableRow.GroupOU = $GroupOU
				$TableRow.Access = "Modify"
				$TableRow.UserDom = Split-Path $User -parent
				$TableRow.UserName = Split-Path $User -leaf
				$FullTable.Rows.Add($TableRow) | Out-Null
			}
		}
	}

	# read-only
	$UserName = $Share.Read
	if ($UserName.Length -gt 0) {
		if ($Share.Share -like "*public")
		{
			$GroupR = "Cargill Authenticated Users"
			$GroupOU = "ou=users,dc=corp,dc=cargill,dc=com"
		}	
		else
		{
			$GroupR = $Group + "~r"
		}		
		foreach ($ReadUsers in $UserName) {
			if ($ReadUsers -like "*;*") {
				$UserSplit = $ReadUsers.Split(',;')
			}
			else {
				$UserSplit = $ReadUsers
			}
			foreach ($User in $UserSplit) {
				$TableRow = $FullTable.NewRow()
				$TableRow.Share = $SharePath -replace "`"",""
				$TableRow.Group = $GroupR
				$TableRow.GroupOU = $GroupOU
				$TableRow.Access = "Read-Only"
				$TableRow.UserDom = Split-Path $User -parent
				$TableRow.UserName = Split-Path $User -leaf
				$FullTable.Rows.Add($TableRow) | Out-Null
			}
		}
	}
}

Remove-Variable Shares
Write-Host "  Creating the GroupDataTable"

$GroupTable = New-Object system.Data.DataTable "Group DataTable" # Setup the Datatable Structure
$TableColg1 = New-Object system.Data.DataColumn Share,([string])
$TableColg2 = New-Object system.Data.DataColumn Group,([string])
$TableColg3 = New-Object system.Data.DataColumn GroupOU,([string])
$TableColg4 = New-Object system.Data.DataColumn Access,([string])
$TableColg5 = New-Object system.Data.DataColumn Modifier,([string])

$GroupTable.columns.add($TableColg1)
$GroupTable.columns.add($TableColg2)
$GroupTable.columns.add($TableColg3)
$GroupTable.columns.add($TableColg4)
$GroupTable.columns.add($TableColg5)

foreach ($FullData in $FullTable) {
	$Compair = 0
	$CompairGroup = $FullData.Group
	foreach ($GroupData in $GroupTable) {
		$Group = $GroupData.Group
		if ($CompairGroup -eq $Group) {
			$Compair = 1
		}
	}
	if ($Compair -eq 0 ) {
		$TableRow = $GroupTable.NewRow()
		$TableRow.Share = $FullData.Share
		$TableRow.Group = $CompairGroup
		$TableRow.GroupOU = $FullData.GroupOU
		$TableRow.Access = $FullData.Access
		if ($CompairGroup -notlike "*~a" -and $Group -notlike "*_public*" -and $Group -ne "") { 
			$Modifier = $CompairGroup.substring(0, ($CompairGroup.Length) - 1) + "a"
			$TableRow.Modifier = $Modifier
		} else {
			$TableRow.Modifier = ""
		}
		$GroupTable.Rows.Add($TableRow) | Out-Null
	}
}

if ($Show) {
	$GroupTable | Select-Object Share,Group,GroupOU,Access | Export-Csv GroupTable.csv -NoTypeInformation
	$FullTable | Select-Object Share,Group,GroupOU,Access,UserDom,UserName | Export-Csv FullTable.csv -NoTypeInformation
}

#  Convert-Share end  #

Write-Host "Creating AD Groups"

#  Create-ADGroup start  #

# Group Types
$GlobalDist = "2"
$DomainLocalSecDist = "4"
$UniversalDist = "8"
$GlobalSec = "-2147483646"
$DomainLocalSec = "-2147483644"
$UniversalSec = "-2147483640"

$count = 0
$runcount = 0
foreach ($Groups in $GroupTable) {
	if ($Groups.Group -ne "" -and $Groups.Group -ne "Cargill Authenticated Users") {
		$count += 1
	}
}

foreach ($Groups in $GroupTable) {
	if ($Groups.Group -ne "" -and $Groups.Group -ne "Cargill Authenticated Users") {
		$runcount += 1
	}
	# creates the groups & sets properties
	$Group = $Groups.Group
	if ($Group -ne "Cargill Authenticated Users") {
		$OUPath = "LDAP://" + $Groups.GroupOU
		$GroupPath = "LDAP://cn=" + $Groups.Group + "," + $Groups.GroupOU
	
		$ADOU = [ADSI]("$OUPath")
		$ADGroup = [ADSI]("$GroupPath")
		
		if (!$ADGroup.Name) {
			$Create = $ADOU.Create("group","cn=" + $Groups.Group)
			$Create.Put("sAMAccountName",$Groups.Group)
			$Create.Put("Description",$Groups.Share)
			$Create.Put("groupType",$DomainLocalSec)
			$Create.psbase.commitchanges() | Out-Null
			if ($error) {
				Write-Logs ($Group + " was not created:") $error
				$ErrNumb += 1
			}
			else {
				Write-Logs ("created " + $Group + " succesfully")
				$CreatedGroup += 1
			}
		}
		else {
			$Create = $ADGroup
			$Create.Put("sAMAccountName",$Groups.Group)
			$Create.Put("Description",$Groups.Share)
			$Create.Put("groupType",$DomainLocalSec)
			$Create.psbase.commitchanges() | Out-Null
		}
		if ($error) {
			Write-Logs ($Group + " was not modified:") $error
			$ErrNumb += 1
		}
		else {
			Write-Logs ("modified " + $Group + " succesfully")
		}
	}
	if (($runcount % 15) -eq 0 -or $runcount -eq $count -and $runcount -ne 0) {
		Write-Host " " $runcount "of" $count "groups created"
	}
}

# If this is not here AD will not have enough time to store the groups before adding them to the folders.

Write-Host "  waiting" $PauseTime "seconds for AD settings to save"

AD-Pause $PauseTime

Write-Host "Modifying AD Groups"

$count = 0
$runcount = 0
foreach ($Groups in $GroupTable) {
	if ($Groups.Group -ne "." -and $Groups.Group -ne "Cargill Authenticated Users") {
		$count += 1
	}
}

if (!$UnManaged) {
	foreach ($Groups in $GroupTable) { # need to break into seperate parts.  1st to set "managed by" second to set "writemembers"
		$runcount += 1
		# sets the security permissions for the ~a group to manage ~m & ~r groups
		$Group = $Groups.Group
		if ($Group -ne "Cargill Authenticated Users") {
			if ($Group -notlike "*~a" -and $Group -notlike "*_public*" -and $Group -ne "") { 
				$GroupPath = "LDAP://cn=" + $Groups.Group + "," + $Groups.GroupOU
				$ModifierPath = "LDAP://cn=" + $Groups.Modifier + "," + $Groups.GroupOU
				
				$ADGroup = [ADSI]("$GroupPath")
				$ADModifier = [ADSI]("$ModifierPath")
				
				if ($Managed) {
					$ModifiersAM = $ADModifier.sAMAccountName
					$GroupsAM = $ADGroup.sAMAccountName
			
					$Domain = Reverse-ADSI $Groups.GroupOU
					$ModifierSecurity = New-Object System.Security.Principal.NTAccount($Domain,$ModifiersAM) # converts the user accounts to securtity accounts
					$ModifierSID = $ModifierSecurity.Translate([System.Security.Principal.SecurityIdentifier]) # converts the account to its SID
					$WriteMembers="bf9679c0-0de6-11d0-a285-00aa003049e2" # the GUID for the write member property
					$Manager = [System.Security.Principal.SecurityIdentifier]$ModifierSID.Value
					$ManagerRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($Manager,"WriteProperty","Allow",$WriteMembers) # allows user to write to the group
					if ($r) {
						Remove-Variable r
					}
					New-Variable r
					If (!($ADGroup.psbase.ObjectSecurity.ModifyAccessRule("Add",$ManagerRule,[ref]$r))) {
						Write-Logs ($ModifiersAM + " was not added with modify permissions to " + $GroupsAM + ":") $error
						$ErrNumb += 1
					} else {
						Write-Logs ("Added " + $ModifiersAM + " with modify permissions to " + $GroupsAM)
					}
				}
				$ModifierDN = $ADModifier.distinguishedName
				$ADGroup.Put("managedBy","$ModifierDN")
				$ADGroup.psbase.commitchanges() | Out-Null
	
				if ($error) {
					Write-Logs ($Group + " `"managedBy`" was not modified:") $error
					$ErrNumb += 1
				} else {
					Write-Logs ("Set `"managedBy`" for " + $Group)
				}
			}
		}
		if (($runcount % 15) -eq 0 -or $runcount -eq $count -and $runcount -ne 0) {
			Write-Host " " $runcount "of" $count "groups modified"
		}
	}
}


#  Create-ADGroup end  #

Write-Host "Creating Folders"

#  Create-Folder start  #

$count = 0
$runcount = $GroupTable
foreach ($Groups in $GroupTable) {
	if ($Groups.Share -ne "") {
		$count += 1
	}
}

foreach ($Groups in $GroupTable) {
	$runcount += 1
	$Test = Test-Path $Groups.Share
	$Share = $Groups.Share
	if ($Test -eq $false) {
		$Create = New-Item -Path $Share -ItemType directory
		$Test = Test-Path $Groups.Share
		if ($Test -eq $true) {
			Write-Logs ("created " + $Share + " succesfully")
			$CreatedFolder += 1
		}
		else {
			Write-Logs ($Share + " was not created:") $error
			$ErrNumb += 1
		}
	}
	else {
		Write-Logs ($Share + " already exists")
	}
	if (($runcount % 15) -eq 0 -or $runcount -eq $count -and $runcount -ne 0) {
		Write-Host " " $runcount "of" $count "folders created"
	}
}

#  Create-Folder end  #

Write-Host "Be Patient:  Setting Folder Permissions - could take several hours"

#  Set-Permissions start  #

# Setting Inheritance to inherit from the parent folder
# Setting Propigation to apply to all child folders
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"

Write-Host "Setting Modify Permissions"

$count = 0
$runcount = 0
foreach ($Groups in $GroupTable) {
	if ($Groups.Access -eq "Modify") {
		$count += 1
	}
}

# Inputs the information into the the Set-ACLs function for all Modify groups
foreach ($Groups in $GroupTable) {
	if ($Groups.Access -eq "Modify") {
		$runcount += 1
		$Domain = Reverse-ADSI $Groups.GroupOU
		$Group = $Domain + "\" + $Groups.Group
		$Share = $Groups.Share
		Set-ACLs $Group $Share "Modify"
	}
	if (($runcount % 15) -eq 0 -or $runcount -eq $count -and $runcount -ne 0) {
		Write-Host " " $runcount "of" $count "modify permissions set"
	}
}

Write-Host "Setting Read Only Permissions"

$count = 0
$runcount = 0
foreach ($Groups in $GroupTable) {
	if ($Groups.Access -eq "Read-Only") {
		$count += 1
	}
}

# Inputs the information into the the Set-ACLs function for all Read-Only groups
foreach ($Groups in $GroupTable) {
	if ($Groups.Access -eq "Read-Only") {
		$runcount += 1
		$Domain = Reverse-ADSI $Groups.GroupOU
		$Group = $Domain + "\" + $Groups.Group
		$Share = $Groups.Share
		Set-ACLs $Group $Share "ReadAndExecute"
		if ($_.Share -like "*_public") {
			$Group = "CORP\Cargill Authenticated Users"
			$Share = $Groups.Share
			Set-ACLs $Group $Share "ReadAndExecute"
		}
	}
	if (($runcount % 15) -eq 0 -or $runcount -eq $count -and $runcount -ne 0) {
		Write-Host " " $runcount "of" $count "read-only permissions set"
	}
}

#  Set-Permissions end  #

Write-Host "Setting group memberships"

#  Add-Users start  #

$count = 0
$runcount = 0
foreach ($Groups in $FullTable) {
	if ($Groups.Group -ne "Cargill Authenticated Users") {
		$count += 1
	}
}

foreach ($Groups in $FullTable) {
	if ($Groups.Group -ne "Cargill Authenticated Users") {
		$runcount += 1
		$Class = "user"
		$UserADSI = Set-ADSI $Groups.UserDom # set the ADSI domain path for the users 
		$UserName = $Groups.UserName
	
		$UserPath = Get-DN $UserName $Class $UserADSI # find the full LDAP path for the user account
		$GroupPath = "LDAP://CN=" + $Groups.Group + "," + $Groups.GroupOU
	
		$ADUser = [ADSI]("$UserPath")
		$ADGroup = [ADSI]("$GroupPath")
		
		$GroupName = $ADGroup.Name
		$MembershipCheck = ($ADGroup.member | where {$_ -eq $ADUser.distinguishedName})
				
		if ($MembershipCheck.length -gt 1) {
			Write-Logs ($Groups.UserDom + "\" + $UserName + " is already a member of " + $Groups.Group + ".  No changes made.")
		}
		elseif ($UserPath -eq $null) {
			Write-Logs ($Groups.UserDom + "\" + $UserName + " could not be added to " + $Groups.Group + ": the account does not exist")
			$NoAccount += 1
		}		
		# adds the user to the group
		else { 
			$GroupMembers = $ADGroup.member
			$objAddMember = $ADGroup.add("$UserPath")
			$ADGroup.setInfo()
		
			if ($error) {
				Write-Logs ($Groups.UserDom + "\" + $UserName + " was not added to " + $GroupName) $error
				$ErrNumb += 1
			}
			else {
				Write-Logs ("added " + $Groups.UserDom + "\" + $ADUser.sAMAccountname + " to " + $GroupName)
			}
		}	
		# adds the _private~m group to the _public~m group
		if ($GroupPath -match "_public~m") { 
			$PrivateGroupPath = $GroupPath -replace "_public","_private"
			$ADPrivateGroup = [ADSI]("$PrivateGroupPath")
			
			$MembershipCheck = ($ADGroup.member | where {$_ -eq $ADPrivateGroup.distinguishedName})
				
			if ($MembershipCheck.length -gt 1) {
				Write-Logs ($Groups.UserDom + "\" + $ADPrivateGroup.name + " is already a member of " + $Groups.Group + ".  No changes made.")
			}
			else {
				$objAddMember = $ADGroup.add("$PrivateGroupPath")
				$ADGroup.setInfo() | Out-Null
				if ($error) {
					Write-Logs ($Groups.UserDom + "\" + $ADGroup.Name + " was not added to " + $GroupName) $error
					$ErrNumb += 1
				}
				else {
					Write-Logs ("added " + $Groups.UserDom + "\" + $ADGroup.Name + " to " + $GroupName)
				}		
			}
		}
	}
	if (($runcount % 15) -eq 0 -or $runcount -eq $count -and $runcount -ne 0) {
		Write-Host " " $runcount "of" $count "user adds to groups"
	}
}
#  Add-Users end  #

if ($CreatedGroup -gt 0) {
	Write-Logs " "
	Write-Logs ("  " + $CreatedGroup + " group(s) created")
}
if ($CreatedFolder -gt 0) {
	Write-Logs " "
	Write-Logs ("  " + $CreatedFolder + " folder(s) created")
}
if ($NoAccount -gt 0) {
	Write-Logs " "
	Write-Logs ("  " + $NoAccount + " user account(s) not found")
}
if ($ErrNumb -gt 0) {
	Write-Logs " "
	Write-Logs ("  " + $ErrNumb + " error(s) encountered")
}	

$end = Get-Date
$runtime = $end - $begin

Write-Logs " "
Write-Logs "Script execution complete"
Write-Logs ("Runtime:  " + $runtime)
Write-Logs " "
Write-Logs "`#===========================================================`#"

$OutArray = $LogArray | Out-File $LogFile -Append -encoding ASCII