################################################################################
#                                                                              #
#  Purpose:                                                                    #
#     Retrieves Active Directory Account Name based on a given First Name,     #
#     Last Name & Domain                                                       #
#                                                                              #
#  Execution:                                                                  #
#     1.)  Gathers information from the command line or usersearch.csv         #
#     2.)  Searches Active Directory in the give Domain for the First Name &   #
#          Last Name                                                           #
#     3.)  Exports the information found into a new csv file                   #
#                                                                              #
#  Usage:                                                                      #
#     .\Get-AccountName.ps1 [first name],[last name],[domain] (/h|/?)          #
#                                                                              #
#  Where:                                                                      #
#     [first name] = Account.givenName - Usually the users first name          #
#     [last name] = Account.SN - Usually the users last name                   #
#     [domain] = domain in which the user account exists                       #
#                                                                              #
#  Note:                                                                       #
#     If no arguments are given in the command line usersearch.csv will be     #
#     imported                                                                 #
#                                                                              #
#  CSV File Format:                                                            #
#     first,last,domain                                                        #
#     [first name],[last name],[domain]                                        #
#                                                                              #
################################################################################

# $erroractionpreference = "Continue"
$arg = [string]$args

# Displays help
if ($arg.ToLower() -match "/h" -or $arg.ToLower() -match "\?") { 
	$HelpMsg = "Purpose:`n   Retrieves Active Directory Account Name based on a given First Name, `n   Last Name & Domain`n`nExecution:`n   1.)  Gathers information from the command line or usersearch.csv`n   2.)  Searches Active Directory in the give Domain for the First Name &`n          Last Name`n   3.)  Exports the information found into a new csv file`n`nUsage:`n   .\Get-LogonID.ps1 [first name],[last name],[domain] (/h|/?)`n`nWhere:`n   [first name] = Account.givenName - Usually the users first name`n   [last name] = Account.SN - Usually the users last name`n   [domain] = domain in which the user account exists`n`nNote:`n   If no arguments are given in the command line usersearch.csv will be`n   imported`n`nCSV File Format:`n   first,last,domain`n   [first name],[last name],[domain]"
	$MsgBox = new-object -comobject wscript.shell
	$Popup = $MsgBox.Popup($HelpMsg,0,"Get-LogonID.ps1")
	exit
}

# single user search
if ($args.Count -eq 3) {
	$Users = new-object psobject
	$Users | add-member noteproperty first $args[0]
	$Users | add-member noteproperty last $args[1]
	$Users | add-member noteproperty domain $args[2]
}
else {
	$Users = Import-Csv usersearch.csv
}
Write-Output $Users
exit
# Logging
function Write-Logs ($LogTxtF,$ErrorF) {
	$now1 = Get-Date -uFormat %x
	$now2 = Get-Date -Format T
	$now = $now1 + " " + $now2 + ":"
	
	if ($ErrorF -ne $null) {
		$ErrMsg = $ErrorF[0].Exception.Message
		Write-Output "$now  ERROR:  $LogTxtF $ErrMsg" | Out-File $LogFile -Append -encoding ASCII
	}
	else {
		Write-Output "$now  $LogTxtF" | Out-File $LogFile -Append -encoding ASCII
	}	
	$error.Clear()
}

# Set script variables
$begin = Get-Date

$LogDate = Get-Date -format "MM-dd-yy.HH.mm.ss"
$LogFile = "Get-LogonID " + $LogDate + ".log"

$usercount = 0
$runcount = 0
$UsersFound = 0

$UserTable = New-Object system.Data.DataTable "Full DataTable" # Setup the Datatable Structure
$TableCol1 = New-Object system.Data.DataColumn First,([string])
$TableCol2 = New-Object system.Data.DataColumn Last,([string])
$TableCol3 = New-Object system.Data.DataColumn Domain,([string])
$TableCol4 = New-Object system.Data.DataColumn Account,([string])

$UserTable.columns.add($TableCol1)
$UserTable.columns.add($TableCol2)
$UserTable.columns.add($TableCol3)
$UserTable.columns.add($TableCol4)

$LogMsg = "`#===========================================================`#"
Write-Logs $LogMsg
$LogMsg = " "
Write-Logs $LogMsg
$LogMsg = "Script execution begun by " + $env:USERDOMAIN + "\" + $env:USERNAME
Write-Logs $LogMsg
$LogMsg = " "
Write-Logs $LogMsg

foreach ($User in $Users) {
	$usercount += 1
}

foreach ($User in $Users) {
	$Found = $True
	$runcount += 1
	$FirstName = $User.first
	$LastName = $User.last -replace " ","-"
	$Domain = $User.domain
	# Setting HomeDirectory, HomeDrive, & optional TerminalServicesProfilePath 
	if ($Domain -like "ap"){
		$ADSIRoot = "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($Domain -like "eu"){
		$ADSIRoot = "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($Domain -like "la"){
		$ADSIRoot = "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($Domain -like "meat"){
		$ADSIRoot = "dc=meat,dc=cargill,dc=com"
	}
	elseif ($Domain -like "na"){
		$ADSIRoot = "dc=na,dc=corp,dc=cargill,dc=com"
	}
	else {
		$ADSIRoot = "dc=corp,dc=cargill,dc=com"
	}
	# searching AD for the user
	$UsersNumber = 0
	$ADRoot = [ADSI]("LDAP://$ADSIRoot")
	$ADSearch = new-object System.DirectoryServices.DirectorySearcher
	$ADSearch.SearchRoot = $ADRoot
	$ADSearch.Filter = "(&(objectCategory=User)(SN=$LastName)(givenName=$FirstName))"
	$ADUsers = $ADSearch.findall()
	[int]$ADUsersFound = $ADUsers.Count
	if ($ADUsersFound -eq 0) {
		$LogMsg = $FirstName + " " + $LastName + " was not found in the " + $Domain.ToUpper() + " domain"
		Write-Logs $LogMsg
		$Found = $false
	}
	elseif ($ADUsersFound -gt 1) {
		$UsersCount = 0
		foreach ($ADUser in $ADUsers) {
			$UsersCount += 1
			Write-Host $UsersCount "::" $ADUser.path
		}
		$UsersNumber = Read-Host "Please input the user number to retrieve"
	}
	if ($Found -eq $true) {
		if ($UsersNumber -le 1) {
			$UsersNumber = 1
		}
		$UserNumber = $UsersNumber - 1
		$ADUserPath = $ADUsers[($UserNumber)].Path
		$ADUser = [ADSI]("$ADUserPath")
		$Account = (([string]$ADUser.userPrincipalName).split("@"))[0]
			
		$TableRow = $UserTable.NewRow()
		$TableRow.First = $FirstName
		$TableRow.Last = $LastName
		$TableRow.Domain = $Domain.ToUpper()
		$TableRow.Account = $Account
		$UserTable.Rows.Add($TableRow)

		$LogMsg = "Found " + $FirstName + " " + $LastName + " in the " + $Domain.ToUpper() + " domain as " + $Account
		Write-Logs $LogMsg
	}
	if (($runcount % 5) -eq 0 -or $runcount -eq $usercount -and $runcount -ne 0) {
		Write-Host " " $runcount "of" $usercount "users searched"
	}
}

$UserTable | Select-Object First,Last,Domain,Account | Export-Csv UserTable.csv -NoTypeInformation

foreach ($User in $UserTable) {
	$UsersFound += 1
}

$LogMsg = " "
Write-Logs $LogMsg
$LogMsg = "  " + $UsersFound + " of " + $UserCount + " user accounts found"
Write-Logs $LogMsg

$end = Get-Date
$runtime = $end - $begin

$LogMsg = " "
Write-Logs $LogMsg
$LogMsg = "Script execution complete"
Write-Logs $LogMsg
$LogMsg = "Runtime:  " + $runtime
Write-Logs $LogMsg
$LogMsg = " "
Write-Logs $LogMsg
$LogMsg = "`#===========================================================`#"
Write-Logs $LogMsg