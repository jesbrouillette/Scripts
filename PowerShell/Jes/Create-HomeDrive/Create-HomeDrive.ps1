################################################################################
#                                                                              #
#                WARNING: THIS SCRIPT CAN TAKE SEVERAL HOURS TO                #
#                   REPLACE PERMISSIONS ON FOLDERS.  CLOSING                   #
#                     BEFORE THE SCRIPT FINISHED CAN CAUSE                     #
#                           FOLDER PERMISSION ERRORS                           #
#                                                                              #
#  ==========================================================================  #
#                                                                              #
#  Note:                                                                       #
#     For best performance run from a machine on a network local to the server #
#     where the shares reside                                                  #
#                                                                              #
#  Purpose:                                                                    #
#     Creates and sets Active Directory Home Drives for users                  #
#                                                                              #
#  Execution:                                                                  #
#     1.)  Gathers information from the csv file selected                      #
#     2.)  Creates & shares the users home folder if it does not exist         #
#     3.)  Grants the user "Modify" access to the folder                       #
#     4.)  Sets HomeDirectory, HomeDrive, & TerminalServicesProfilePath        #
#              (if selected)                                                   #
#                                                                              #
#  Usage:                                                                      #
#     .\Create-HomeDrive.ps1 (/h|/?)                                           #
#                                                                              #
#  CSV File Format:                                                            #
#     username,domain,server,shareloc,drivelett,tsprof                         #
#     [username],[domain],[server],[shareloc],[drivelett],[tsprof]             #
#                                                                              #
#     Where:                                                                   #
#         [username] = logon id for the user needing changed                   #
#         [domain] = domain in which the user account exists                   #
#         [server] = server where the home folders exists or will be created   #
#         [shareloc] = physical location on the server to the parent folder of #
#             the home drive                                                   #
#         [drivelett] = drive letter for the home drive to be mapped           #
#         [tsprof] = location of the Terminal Server Profile Path (optional)   #
#                                                                              #
################################################################################

$erroractionpreference = "Inquire"
$arg = [string]$args

# Displays help
if ($arg.ToLower() -match "/h" -or $arg.ToLower() -match "\?") { 
	$HelpMsg = "          WARNING: THIS SCRIPT CAN TAKE SEVERAL HOURS TO REPLACE`n             PERMISSIONS ON FOLDERS.  CLOSING THE SCRIPT BEFORE IT`n                   IS FINISHED CAN CAUSE FOLDER PERMISSION ERRORS`n`n  ==============================================  `n`n  Note:`n     For best performance run from a machine on a network local to the server`n     where the shares reside`n`n  Purpose:`n     Creates and sets Active Directory Home Drives for users`n`n  Execution:`n     1.)  Gathers information from the csv file selected`n     2.)  Creates & shares the users home folder if it does not exist`n     3.)  Grants the user 'Modify' access to the folder`n     4.)  Sets HomeDirectory, HomeDrive, & TerminalServicesProfilePath`n              (if selected)`n`n  Usage:`n     .\Create-HomeDrive.ps1 (/h|/?)`n`n  CSV File Format:`n     username,domain,server,shareloc,drivelett,tsprof`n     [username],[domain],[server],[shareloc],[drivelett],[tsprof]`n`n     Where:`n         [username] = logon id for the user needing changed`n         [domain] = domain in which the user account exists`n         [server] = server where the home folders exists or will be created`n         [shareloc] = physical location on the server to the parent folder of`n             the home drive`n         [drivelett] = drive letter for the home drive to be mapped`n         [tsprof] = location of the Terminal Server Profile Path (optional)"
	$MsgBox = new-object -comobject wscript.shell
	$Popup = $MsgBox.Popup($HelpMsg,0,"Secure-Folder.ps1")
	exit
}

# Set script variables
$begin = Get-Date
$Users = Import-Csv homedir.csv
$LocalHost = ($env:computername).ToLower()
$Log = "Create-HomeDrive.log"

# Setting Inheritance to inherit from the parent folder
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
# Setting Propagation to apply to all child folders
$propagation = [system.security.accesscontrol.PropagationFlags]"None"

#--------------------------#
#  Define-Functions start  #
#--------------------------#

# Logging
function Write-Logs ($LogTxtF,$ErrorF) {
	$now1 = Get-Date -uFormat %x
	$now2 = Get-Date -Format T
	$now = $now1 + " " + $now2 + ":"
	
	if ($ErrorF -ne $null) {
		$ErrMsg = $ErrorF[0].Exception.Message
		if ($ErrMsg -like "*already exists*") {
			Write-Output "$now  $LogTxtF it already exists" | Out-File $Log -Append -encoding ASCII
		}
		else {
			Write-Output "$now  ERROR:  $LogTxtF $ErrMsg" | Out-File $Log -Append -encoding ASCII
		}
	}
	else {
		Write-Output "$now  $LogTxtF" | Out-File $Log -Append -encoding ASCII
	}	
	$error.Clear()
}

#------------------------#
#  Define-Functions end  #
#------------------------#

$LogMsg = "`#===========================================================`#"
Write-Logs $LogMsg
$LogMsg = " "
Write-Logs $LogMsg
$LogMsg = "Script execution begun by " + $env:USERDOMAIN + "\" + $env:USERNAME
Write-Logs $LogMsg
$LogMsg = " "
Write-Logs $LogMsg

# verifies the local computer name and checks against the server column.  if they are they same no credentials are required
$servercount = 0
$usercount = 0
$createdcount = 0
foreach ($User in $Users) {
	$HomeServer = ($User.server).ToLower()
	if ($LocalHost -ne $HomeServer) {
		$servercount += 1
	}
	$usercount += 1
}

if ($servercount -gt 0) {
	$cred = Get-Credential
}

# begin work
foreach ($User in $Users) {
	$createdcount += 1
	$UserName = ($User.username).ToLower()
	$HomeServer = ($User.server).ToLower()
	$DomainUser = ($User.domain).ToUpper() + "\" + $UserName
	$HomeFolder = ($User.shareloc).ToLower() + $UserName
	$Share = $UserName + "`$"
	$UNCPath = "\\" + $HomeServer + "\" + $Share
	$UNCCreate = "\\" + $HomeServer + "\" + $HomeFolder -replace "`:","`$"
	$HomeDrvLet = ($User.drivelett).ToUpper()
	$TSProfPath = $User.tsprof

	Write-Host (get-date).ToString("MM/dd/yy hh:mm:ss")":: Creating/Editing settings for" $DomainUser "::" $createdcount "of" $usercount

	$LogMsg = "`#=================`#"
	Write-Logs $LogMsg
	$LogMsg = "`#  " + $DomainUser + "  `#"
	Write-Logs $LogMsg
	$LogMsg = "`#=================`#"
	Write-Logs $LogMsg


	# Create the folder if it does not exist
	$Test = Test-Path $UNCCreate
	if ($Test -eq $false) {
		$Create = New-Item -Path $UNCCreate -ItemType directory
		$Test = Test-Path $UNCCreate
		if ($Test -eq $true) {
			$LogMsg = "created " + $UNCCreate + " succesfully"
			Write-Logs $LogMsg
		}
		else {
			$LogMsg = $UNCCreate + " was not created:"
			Write-Logs $LogMsg $error
			$strErrorNumb += 1
		}
	}
	else {
		$LogMsg = $UNCCreate + " already exists"
		Write-Logs $LogMsg
	}

	# Creating the share
	# for local shares
	if ($LocalHost -eq $HomeServer) {
		$wmiShare = [wmiClass] 'Win32_share'
		$Create = $wmiShare.Create($HomeFolder,$Share,0)
	}
	# for remote shares
	else {
		$ConOpts = new-object management.connectionoptions
		$ConOpts.Username = $cred.UserName
		$ConOpts.SecurePassword = $cred.Password
		$ConnectPath = "\\" + $HomeServer + "\root\cimv2"
		$Scope = new-object management.managementscope $ConnectPath,$ConOpts
		$Scope.Connect()
		$MgmtPath = new-object management.managementpath "Win32_Share"
		$ObjGetOpts = new-object management.objectgetoptions
		$wmiShare = new-object management.managementclass $Scope,$MgmtPath,$ObjGetOpts
		$Create = $wmiShare.Create($HomeFolder,$Share,0)
	}
	# logging
	if ($Create.ReturnValue -eq 0) {
		$LogMsg = "share " + $Share + " created on " + $HomeServer
		Write-Logs $LogMsg
	}
	elseif ($Create.ReturnValue -eq 22) {
		$LogMsg = "share " + $Share + " already exists on " + $HomeServer
		Write-Logs $LogMsg
	}
	else {
		$LogMsg = $Share + " was not created on " + $HomeServer
		Write-Logs $LogMsg $error
	}
		
	# Setting permissions
	$ACL = Get-Acl $UNCCreate
	$AccessRule = New-Object System.Security.Accesscontrol.FileSystemAccessRule($DomainUser,"Modify",$inherit,$propagation,"Allow")
	$ACL.AddAccessRule($AccessRule)
	$SetACL = Set-Acl $UNCCreate $ACL
	# logging
	if ($error) { 
		$LogMsg = $DomainUser + " was not added to " + $UNCPath + ":"
		Write-Logs $LogMsg $error
		$ErrorNumb += 1
	}
	else { 
		$LogMsg = "added " + $DomainUser + " to " + $UNCPath + " with Modify access"
		Write-Logs $LogMsg
	}

	# Setting HomeDirectory, HomeDrive, & optional TerminalServicesProfilePath 
	if ($User.domain -like "ap"){
		$ADSIRoot = "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($User.domain -like "eu"){
		$ADSIRoot = "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($User.domain -like "la"){
		$ADSIRoot = "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($User.domain -like "meat"){
		$ADSIRoot = "dc=meat,dc=cargill,dc=com"
	}
	elseif ($User.domain -like "na"){
		$ADSIRoot = "dc=na,dc=corp,dc=cargill,dc=com"
	}
	else {
		$ADSIRoot = "dc=corp,dc=cargill,dc=com"
	}
	# searching AD for the user
	$ADRoot = [ADSI]("LDAP://$ADSIRoot")
	$ADSearch = new-object System.DirectoryServices.DirectorySearcher
	$ADSearch.SearchRoot = $ADRoot
	$ADSearch.Filter = "(&(objectCategory=User)(sAMAccountName=$UserName))"
	$ADUsers = $ADSearch.findall()
	if ($ADUsers -eq $null) {
		$LogMsg = $DomainUser + " was not found"
		Write-Logs $LogMsg
	}
	else {
		$ADUserPath = $ADUsers[0].Path
		$ADUser = [ADSI]("$ADUserPath")
		
		$GetHomeDir = $ADUser.homeDirectory
		$GetHomeDri = $ADUser.homeDrive
		$GetTSProf =  $ADUser.psbase.invokeGet("TerminalServicesProfilePath")
		
		$ADUser.Put("homeDirectory","$UNCPath")
		$ADUser.Put("homeDrive","$HomeDrvLet")
		if ($TSProfPath.Length -gt 0) {
			$ADUser.psbase.invokeSet("TerminalServicesProfilePath","$TSProfPath")
		}
		$Modify = $ADUser.SetInfo()
		# logging
		if ($error) {
			$LogMsg = $DomainUser + " was not modified:"
			Write-Logs $LogMsg $error
			$ErrorNumb += 1
		}
		else {
			$LogMsg = "modified " + $DomainUser + " succesfully"
			Write-Logs $LogMsg
			$LogMsg = "`tHome Directory changed from " + $GetHomeDir + " to " + $UNCPath
			Write-Logs $LogMsg
			$LogMsg = "`tHome Drive changed from " + $GetHomeDri + ":\ to " + $HomeDrvLet + ":\"
			Write-Logs $LogMsg
			if ($TSProfPath.Length -gt 0) {
				$LogMsg = "`tTerminal Services Profile Path changed from " + $GetTSProf + " to " + $TSProfPath
				Write-Logs $LogMsg
			}
		}
	}
	$LogMsg = " "
	Write-Logs $LogMsg
}

$end = Get-Date
$runtime = $end - $begin

$LogMsg = "Script execution complete"
Write-Logs $LogMsg
$LogMsg = "Runtime:  " + $runtime
Write-Logs $LogMsg
$LogMsg = " "
Write-Logs $LogMsg
$LogMsg = "`#===========================================================`#"
Write-Logs $LogMsg