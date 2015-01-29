# usage .\Add-User.ps1 "[groupname]" [domain] [userlist]
# must be run using a corp\mwts_ account

function GetDN ($strSAMNameF,$classF,$strADSIF) { # function retuns the full CN of the user or group
	$strRoot = [ADSI]"LDAP://$strADSIF"
	$objSearcher = new-object System.DirectoryServices.DirectorySearcher 
	$objSearcher.SearchRoot = $strRoot
	$objSearcher.Filter = "(&(objectCategory=$classF)(sAMAccountName=$strSAMNameF))"
	$objUsers = $objSearcher.findall()

	if ($objUsers.count -gt 1) {
		$intCount = 0
		foreach($objUser in $objUsers) {
			write-output $intCount ": " $objUser.path
			$intCount = $intCount + 1
		}
		$strSelection = Read-Host "Please select item: "
		return $objUsers[$strSelection].path
	}
	else {
		return $objUsers[0].path
	}
} # end function

function SetADSI ($strDomainF) {# sets the correct ADSI container for each domain
	if ($strDomainF.ToLower() -eq "ap"){
		return "dc=ap,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "corp"){
		return "dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "eu"){
		return "dc=eu,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "la"){
		return "dc=la,dc=corp,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "meat"){
		return "dc=meat,dc=cargill,dc=com"
	}
	elseif ($strDomainF.ToLower() -eq "na"){
		return "dc=na,dc=corp,dc=cargill,dc=com"
	}
	else {
		$strDomainUp = $strDomainF.ToUpper()
		Write-Output "Domain information is incorrect for $strDomainUp"
		exit
	}
} # end SetADSI function

# ----------------------------#
# Start Script Execution Here #
# ----------------------------#

$list = Import-Csv "mods.csv"

foreach ($line in $list) {
	$groupADSI = SetADSI $line.GroupDom # set the full ADSI path for the domain
	$groupClass = "group"
	$groupCN = GetDN $list.Group $groupClass $groupADSI # find the group

	$userADSI = SetADSI $line.UserDom
	$userClass = "user"
	$userName = [string]$line.User

	$userCN = GetDN $userName $userClass $userADSI # find the user
		
	$userAD = [ADSI]("$userCN")
	$groupAD = [ADSI]("$groupCN")
	
	$checkMembership = ($groupAD.member | where {$_ -eq $userAD.distinguishedName})
		
	if ($checkMembership.length -gt 1) {
		Write-Output "User is already member of group.  No change made."
	}
	else
	{
	
		# adds the user to the group
		$groupMembers = $groupAD.member
		$groupAD.member = $groupMembers + $userAD.distinguishedName
		$groupAD.setinfo()
		$userDom = $line.UserDom
		$userSAM = $userAD.sAMAccountName
		$groupSAM =$groupAD.sAMAccountName
		Write-Output "added $userDom `b`\ `b$userSAM to $groupSAM"
	}
}