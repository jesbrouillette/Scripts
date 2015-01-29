param (
	[string] $csv, #file to import (optional - you will be prompted if not specified)
	[switch] $help, #Displays the help message
	[switch] $remove, #removes existing folder security before starting
	[switch] $show, #exports all groups and all settings to .csv
	[switch] $unManaged, #Does not set "manager can update membership list"
	[switch] $whatif #same a -show, but does not execute any changes
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
#     -unmanaged - Does not set "manager can update membership list"           #
#     -whatif - same a -show but does not execute any changes                  #
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

$pause = 10 # how long to wait for AD to save groups
$CreatedGroup = 0
$CreatedFolder = 0
$NoAccount = 0
$ErrNumb = 0
$date = Get-Date -format "MM-dd-yy.HH.mm.ss"
$logFile = "Secure-Folder " + $date + ".log"
$log = New-Object System.Collections.ArrayList
$msgBox = new-object -comobject wscript.shell

if ($help) { #Displays help
	$msg = "                                                                              
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
   MUST validate the folder structure before execution.  Please refrer to
   the MWTS KB for details.

Execution:                                                                  
   1.)  Gathers information from the csv file selected                      
   2.)  Creates AD User Group                                               
   3.)  Creates the folders, if they need created                           
   4.)  Adds the proper AD Security Group and settings for each folder      
   5.)  Adds users to the proper AD Security Group                          

Usage:                                                                      
   .\Secure-Folder.ps1 (-help, -csv, -show, -remove, -unmanaged, -whatif)

Switches:
   -help - Displays this message
   -csv - file to import (optional - you will be prompted if not specified)
   -remove - removes existing folder security before starting
   -show - exports all groups and all settings to .csv files
   -unmanaged - Does not set `"manager can update membership list`"
   -whatif - same a -show but does not execute any changes

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

	[void]$msgBox.Popup($msg,0,"Secure-Folder.ps1")
	exit
}

$msg = "Folders must not contain comma's or apostrophe's.`n`t Does your list contain these?"
$notify = $msgBox.Popup($msg,0,"Secure-Folders.ps1",4)

if ($notify -eq 6) {
	$msg = "Please remove or rename the folders  `n      with commas (,) apostrophies (') or parenthasies (())"
	[void]$msgBox.Popup($msg,0,"Secure-Folders.ps1",0)
	exit
}

#  Define-Functions start  #

function MatchData ($new,$existing,$count) { #Share,Original,Trim
	if (!$count) { $count = 0 }
	foreach ($line in $existing) {
		if (($new.Trim -eq $line.Trim) -and ($new.Share -ne $line.Share)) {
			$count += 1
			$row = "" | Select Share,Original,Trim
			$row.Share = $new.Share
			$row.Original = $new.Original
			$row.Trim = ($group.TrimEnd($group.Length - $count.Length)) + $count.ToString()
			MatchData $row $existing $count
		}
	}
	return $new.Trim
}

function WriteLogs ($logMsg,$logErr) {
	$now = (Get-Date -uFormat %x) + " " + (Get-Date -Format T) + ":"
	
	if ($logErr) {
		$errMsg = $logErr[0].Exception.Message
		if ($errMsg -like "*already exists*") {
			[Void]$log.Add("$now  $logMsg it already exists")
		}
		else {
			[Void]$log.Add("$now  ERROR:  $logMsg $errMsg")
		}
	}
	else {
		[Void]$log.Add("$now  $logMsg")
	}	
	$error.Clear()
}

function GetDN ($sAMName,$classType,$lDAPPath) { # function retuns the full CN of the user or group
	$ADSIRoot = [ADSI]("LDAP://$lDAPPath")
	$ADSearch = new-object System.DirectoryServices.DirectorySearcher
	$ADSearch.SearchRoot = $ADSIRoot
	$ADSearch.Filter = "(&(objectCategory=$classType)(sAMAccountName=$sAMName))"
	$FoundUsers = $ADSearch.findall()
	$FoundUsers[0].path
} # end GetDN function

function ADPause ($pauseTime) { # Pauses until the first AD Group has been successfully stored.
	$count = 0
	do {
		Start-Sleep -Seconds $pauseTime
		$group = $fullTable[0].Group
		$Domain = ReverseADSI $fullTable[0].GroupOU
		$classType = "group"
		$approverGroupDSI = SetADSI $Domain # set the domain path for the group
		$groupPath = GetDN $group $classType $approverGroupDSI # find the full LDAP path for the group account
	} until ($groupPath -ne $null -or $count -ge 180)
	
	if ($count -eq 180) {
		WriteLogs "AD Groups are not storing properly.`nSecure-Folders.ps1 Exiting"
		exit
	} else { WriteLogs "AD Groups stored properly" }
}

function SetACLs ($groupF,$shareF,$AccessTypeF) { # Sets the folder security
	WriteLogs ("Adding " + $groupF + " to " + $shareF)
	if ($remove) {
		# Removes all ACL's for the current group if they have access already
		$ACL = Get-Acl $shareF
		foreach ($ACLAccess in $ACL.Access) {
			$AccessIDRef = $ACLAccess.IdentityReference
			if ($AccessIDRef -eq $groupF) {
				$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupF,"FullControl",$inherit, $propagation,"Allow")
				[Void]$ACL.RemoveAccessRuleAll($AccessRule)
				Set-Acl $shareF $ACL
				if ($error) { 
					WriteLogs ($groupF + " was not removed from " + $shareF + ":") $error
					Set-Variable ErrNumb -Value +1 -Scope 1
				}
				else { 
					WriteLogs ($groupF + " was removed from " + $shareF)
				}
			}
		}
	}

	# Sets the appropriate ACL's for the current group
	$ACL = Get-Acl $shareF
	$AccessRule = New-Object System.Security.Accesscontrol.FileSystemAccessRule($groupF,$AccessTypeF,$inherit,$propagation,"Allow")
	[Void]$ACL.AddAccessRule($AccessRule)
	Set-Acl $shareF $ACL
	if ($error) { 
		WriteLogs ($groupF + " was not added to " + $shareF + ":") $error
		Set-Variable ErrNumb -Value +1 -Scope 1
	}
	else { 
		WriteLogs ($groupF + " was added to " + $shareF + " with " + $AccessTypeF + " access")
	}
} # end SetACLs function

function SetADSI ($DomainF) {# sets the correct ADSI container for each domain
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
} # end SetADSI function

function ReverseADSI ($DomainF) { # sets the correct domain for the given adsi path
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
} # end ReverseADSI function

#  Define-Functions end  #

$begin = Get-Date
WriteLogs "`#===========================================================`#"
WriteLogs " "
WriteLogs ("Script execution begun by " + $env:UserDomainAIN + "\" + $env:USERNAME)
WriteLogs " "

#  Convert-Share start  #

if (!$csv) {
	[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	$openFile = New-Object Windows.Forms.OpenFileDialog
	$openFile.Title = "Open - Share Folder Conversion List"
	$openFile.Filter = "Comma Seperated Value (*.csv)|*.csv"
	[Void]$openFile.ShowDialog()
	$shares = Import-Csv $openFile.FileName
 } else {
 	$shares = Import-Csv $csv
}

$fullTable = @()
$trimTable = @()
$groupTable = @()

Write-Host "Creating the full table of shares, users, and group names"

foreach ($share in $shares) {
	$row = "" | Select Share,Group,GroupOU,Access,UserDomain,UserName
	$sharePath = $share.share
	$group = $sharePath.ToLower() -replace "\\","~" -replace " ","_" -replace "~~","" -replace "data","" -replace ",","" -replace "'",""
	if ($group.length -gt 62) {
		$group = $group.TrimEnd($group.Substring(62))
		$trimRow = "" | Select Share,Original,Trim
		$trimRow.Share = $sharePath
		$trimRow.Original = $group
		$trimRow.Trim = $group.TrimEnd($group.Substring(62))
		$match = MatchData $trimRow $trimTable
		$trimRow.Trim = $match
		$group = $match
		$trimTable += $trimRow
	}
	$approverGroup = $group + "~a"
	$modifyGroup = $group + "~m"
	$groupOU = $share.GroupOU
			
	# approvers
	$approvers = $share.Approve
	if ($approvers.Length -gt 0) {
		if ($approvers -like "*;*") {
			$approvers = $approvers.Split(',;')
		}
		foreach ($approver in $approvers) {
			$row.Share = $sharePath -replace "`"",""
			$row.Group = $approverGroup
			$row.GroupOU = $groupOU
			$row.Access = "Approver"
			$row.UserDomain = Split-Path $approver -parent
			$row.UserName = Split-Path $approver -leaf
			$fullTable += $row
		}
	}

	# modify
	$UserName = $share.Modify
	if ($UserName.Length -gt 0) {
		foreach ($ModifyUsers in $UserName) {
			if ($ModifyUsers -like "*;*") {
				$UserSplit = $ModifyUsers.Split(',;')
			}
			else {
				$UserSplit = $ModifyUsers
			}
			foreach ($User in $UserSplit) {
				$row = "" | Select Share,Group,GroupOU,Access,UserDomain,UserName
				$row.Share = $sharePath -replace "`"",""
				$row.Group = $modifyGroup
				$row.GroupOU = $groupOU
				$row.Access = "Modify"
				$row.UserDomain = Split-Path $User -parent
				$row.UserName = Split-Path $User -leaf
				$fullTable += $row
			}
		}
	}

	# read-only
	$UserName = $share.Read
	if ($UserName.Length -gt 0) {
		if ($share.Share -like "*public")
		{
			$readGroup = "Cargill Authenticated Users"
			$groupOU = "ou=users,dc=corp,dc=cargill,dc=com"
		}	
		else
		{
			$readGroup = $group + "~r"
		}		
		foreach ($ReadUsers in $UserName) {
			if ($ReadUsers -like "*;*") {
				$UserSplit = $ReadUsers.Split(',;')
			}
			else {
				$UserSplit = $ReadUsers
			}
			foreach ($User in $UserSplit) {
				$row = "" | Select Share,Group,GroupOU,Access,UserDomain,UserName
				$row.Share = $sharePath -replace "`"",""
				$row.Group = $readGroup
				$row.GroupOU = $groupOU
				$row.Access = "Read-Only"
				$row.UserDomain = Split-Path $User -parent
				$row.UserName = Split-Path $User -leaf
				$fullTable += $row
			}
		}
	}
}

Write-Host "creating the list of unique groups and folders"

foreach ($FullData in $fullTable) {
	$row = "" | Select Share,Group,GroupOU,Access,Modifier
	$Compair = 0
	$CompairGroup = $FullData.Group
	foreach ($groupData in $groupTable) {
		$group = $groupData.Group
		if ($CompairGroup -eq $group) {
			$Compair = 1
		}
	}
	if ($Compair -eq 0 ) {
		$row.Share = $FullData.Share
		$row.Group = $CompairGroup
		$row.GroupOU = $FullData.GroupOU
		$row.Access = $FullData.Access
		if ($CompairGroup -notlike "*~a" -and $group -notlike "*_public*" -and $group -ne "") { 
			$Modifier = $CompairGroup.substring(0, ($CompairGroup.Length) - 1) + "a"
			$row.Modifier = $Modifier
		} else {
			$row.Modifier = ""
		}
		$groupTable += $row
	}
}

if ($show -or $whatif) {
	$groupTable | Select-Object Share,Group,GroupOU,Access | Export-Csv GroupTable.csv -NoTypeInformation
	$fullTable | Select-Object Share,Group,GroupOU,Access,UserDomain,UserName | Export-Csv FullTable.csv -NoTypeInformation
	if ($whatif) { exit }
}

if ($groupTable.Count -eq $null) { $groupCount = 1 }
else {$groupCount = $groupTable.Count }
if ($shares.Count -eq $null) { $sharesCount = 1 }
else {$sharesCount = $shares.Count }

rv shares
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
foreach ($groups in $groupTable) {
	if ($groups.Group -ne "" -and $groups.Group -ne "Cargill Authenticated Users") {
		$count += 1
	}
	# creates the groups & sets properties
	$group = $groups.Group
	if ($group -ne "Cargill Authenticated Users") {
		$OUPath = "LDAP://" + $groups.GroupOU
		$groupPath = "LDAP://cn=" + $groups.Group + "," + $groups.GroupOU
	
		$ADOU = [ADSI]("$OUPath")
		$ADGroup = [ADSI]("$groupPath")
		
		if (!$ADGroup.Name) {
			$Create = $ADOU.Create("group","cn=" + $groups.Group)
			$Create.Put("sAMAccountName",$groups.Group)
			$Create.Put("Description",$groups.Share)
			$Create.Put("groupType",$DomainLocalSec)
			[Void]$Create.psbase.commitchanges()
			if ($error) {
				WriteLogs ($group + " was not created:") $error
				$ErrNumb += 1
			}
			else {
				WriteLogs ("created " + $group + " succesfully")
				$CreatedGroup += 1
			}
		}
		else {
			$Create = $ADGroup
			$Create.Put("sAMAccountName",$groups.Group)
			$Create.Put("Description",$groups.Share)
			$Create.Put("groupType",$DomainLocalSec)
			[Void]$Create.psbase.commitchanges()
		}
		if ($error) {
			WriteLogs ($group + " was not modified:") $error
			$ErrNumb += 1
		}
		else {
			WriteLogs ("modified " + $group + " succesfully")
		}
	}
	if (($count % 15) -eq 0 -or $count -eq $groupTable.Count -and $count -ne 0) {
		Write-Host " " $count "of" $groupTable.Count "groups created"
	}
}

# If this is not here AD will not have enough time to store the groups before adding them to the folders.
Write-Host "  waiting" $pause "seconds for AD settings to save"
ADPause $pause

Write-Host "Modifying AD Groups"
$count = 0
if (!$unManaged) {
	foreach ($groups in $groupTable) {
		$count += 1
		# sets the security permissions for the ~a group to manage ~m & ~r groups
		$group = $groups.Group
		if ($group -ne "Cargill Authenticated Users") {
			if ($group -notlike "*~a" -and $group -notlike "*_public*" -and $group -ne "") { 
				$groupPath = "LDAP://cn=" + $groups.Group + "," + $groups.GroupOU
				$ModifierPath = "LDAP://cn=" + $groups.Modifier + "," + $groups.GroupOU
				
				$ADGroup = [ADSI]("$groupPath")
				$ADModifier = [ADSI]("$ModifierPath")
				
				$ModifiersAM = $ADModifier.sAMAccountName
				$groupsAM = $ADGroup.sAMAccountName
		
				$Domain = ReverseADSI $groups.GroupOU
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
					WriteLogs ($ModifiersAM + " was not added with modify permissions to " + $groupsAM + ":") $error
					$ErrNumb += 1
				} else {
					WriteLogs ("Added " + $ModifiersAM + " with modify permissions to " + $groupsAM)
				}
				$ModifierDN = $ADModifier.distinguishedName
				$ADGroup.Put("managedBy","$ModifierDN")
				[Void]$ADGroup.psbase.commitchanges()
	
				if ($error) {
					WriteLogs ($group + " `"managedBy`" was not modified:") $error
					$ErrNumb += 1
				} else {
					WriteLogs ("Set `"managedBy`" for " + $group)
				}
			}
		}
		if (($count % 15) -eq 0 -or $count -eq $groupTable.Count -and $count -ne 0) {
			Write-Host " " $count "of" $groupTable.Count "groups modified"
		}
	}
}

#  Create-Folder start  #
Write-Host "Creating Folders"
$count = 0
foreach ($groups in $groupTable) {
	$count += 1
	$Test = Test-Path $groups.Share
	$share = $groups.Share
	if ($Test -eq $false) {
		$Create = New-Item -Path $share -ItemType directory
		$Test = Test-Path $groups.Share
		if ($Test -eq $true) {
			WriteLogs ("created " + $share + " succesfully")
			$CreatedFolder += 1
		}
		else {
			WriteLogs ($share + " was not created:") $error
			$ErrNumb += 1
		}
	}
	else {
		WriteLogs ($share + " already exists")
	}
	if (($count % 15) -eq 0 -or $count -eq $groupTable.Count -and $count -ne 0) {
		Write-Host " " $count "of" $groupTable.Count "folders created"
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

# Inputs the information into the the SetACLs function for all Modify groups
$count = 0
foreach ($groups in $groupTable) {
	$count += 1
	if ($groups.Access -eq "Modify") {
		$Domain = ReverseADSI $groups.GroupOU
		$group = $Domain + "\" + $groups.Group
		$share = $groups.Share
		SetACLs $group $share "Modify"
	}
	if (($count % 15) -eq 0 -or $count -eq $groupTable.Count -and $count -ne 0) {
		Write-Host " " $count "of" $groupTable.Count "modify permissions set"
	}
}

Write-Host "Setting Read Only Permissions"

# Inputs the information into the the SetACLs function for all Read-Only groups
$count = 0
foreach ($groups in $groupTable) {
	$count += 1
	if ($groups.Access -eq "Read-Only") {
		$Domain = ReverseADSI $groups.GroupOU
		$group = $Domain + "\" + $groups.Group
		$share = $groups.Share
		SetACLs $group $share "ReadAndExecute"
		if ($_.Share -like "*_public") {
			$group = "CORP\Cargill Authenticated Users"
			$share = $groups.Share
			SetACLs $group $share "ReadAndExecute"
		}
	}
	if (($count % 15) -eq 0 -or $count -eq $groupTable.Count -and $count -ne 0) {
		Write-Host " " $count "of" $groupTable.Count "read-only permissions set"
	}
}

#  Set-Permissions end  #

Write-Host "Setting group memberships"

#  Add-Users start  #

foreach ($groups in $fullTable) {
	if ($groups.Group -ne "Cargill Authenticated Users") {
		$count += 1
		$Class = "user"
		$UserADSI = SetADSI $groups.UserDomain # set the ADSI domain path for the users 
		$UserName = $groups.UserName
	
		$UserPath = GetDN $UserName $Class $UserADSI # find the full LDAP path for the user account
		$groupPath = "LDAP://CN=" + $groups.Group + "," + $groups.GroupOU
	
		$ADUser = [ADSI]("$UserPath")
		$ADGroup = [ADSI]("$groupPath")
		
		$groupName = $ADGroup.Name
		$MembershipCheck = ($ADGroup.member | where {$_ -eq $ADUser.distinguishedName})
				
		if ($MembershipCheck.length -gt 1) {
			WriteLogs ($groups.UserDomain + "\" + $UserName + " is already a member of " + $groups.Group + ".  No changes made.")
		}
		elseif ($UserPath -eq $null) {
			WriteLogs ($groups.UserDomain + "\" + $UserName + " could not be added to " + $groups.Group + ": the account does not exist")
			$NoAccount += 1
		}		
		# adds the user to the group
		else { 
			$modifyGroupembers = $ADGroup.member
			$objAddMember = $ADGroup.add("$UserPath")
			$ADGroup.setInfo()
		
			if ($error) {
				WriteLogs ($groups.UserDomain + "\" + $UserName + " was not added to " + $groupName) $error
				$ErrNumb += 1
			}
			else {
				WriteLogs ("added " + $groups.UserDomain + "\" + $ADUser.sAMAccountname + " to " + $groupName)
			}
		}	
		# adds the _private~m group to the _public~m group
		if ($groupPath -match "_public~m") { 
			$PrivateGroupPath = $groupPath -replace "_public","_private"
			$ADPrivateGroup = [ADSI]("$PrivateGroupPath")
			
			$MembershipCheck = ($ADGroup.member | where {$_ -eq $ADPrivateGroup.distinguishedName})
				
			if ($MembershipCheck.length -gt 1) {
				WriteLogs ($groups.UserDomain + "\" + $ADPrivateGroup.name + " is already a member of " + $groups.Group + ".  No changes made.")
			}
			else {
				$objAddMember = $ADGroup.add("$PrivateGroupPath")
				[Void]$ADGroup.setInfo()
				if ($error) {
					WriteLogs ($groups.UserDomain + "\" + $ADGroup.Name + " was not added to " + $groupName) $error
					$ErrNumb += 1
				}
				else {
					WriteLogs ("added " + $groups.UserDomain + "\" + $ADGroup.Name + " to " + $groupName)
				}		
			}
		}
	}
	if (($count % 15) -eq 0 -or $count -eq $fullTable.Count -and $count -ne 0) {
		Write-Host " " $count "of" $fullTable.Count "user adds completed"
	}
}
#  Add-Users end  #

if ($CreatedGroup -gt 0) { WriteLogs ("  " + $CreatedGroup + "  of " + $groupCount + " group(s) created") }
elseif (($groupCount - $CreatedGroup) -gt 0) { WriteLogs ("  " + ($groupCount - $CreatedGroup) "  groups already existed or could not be created")  }
if ($CreatedFolder -gt 0) { WriteLogs ("  " + $CreatedFolder + " of " + $sharesCount + " folder(s) created") }
elseif (($sharesCount - $CreatedFolder) -gt 0) { WriteLogs ("  " + ($sharesCount - $CreatedFolder)) "  folders already existed or could not be created" }
if ($NoAccount -gt 0) {	WriteLogs ("  " + $NoAccount + " user account(s) not found") }
else { WriteLogs ("  All user accounts were valid") }
WriteLogs ("  " + $ErrNumb + " error(s) encountered")

$end = Get-Date
$runtime = $end - $begin

WriteLogs " "
WriteLogs "Script execution complete"
WriteLogs ("Runtime:  " + $runtime)
WriteLogs " "
WriteLogs "`#===========================================================`#"

$OutArray = $log | Out-File $logFile -Append -encoding ASCII