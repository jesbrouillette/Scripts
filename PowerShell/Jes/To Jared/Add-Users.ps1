# usage .\Add-User.ps1 "[groupname]" [domain] [userlist]
# must be run using a corp\mwts_ account

function get-dn ($strSAMNameF,$strClassTypeF,$strADSIF) { # function retuns the full CN of the user or group
	$strRoot = [ADSI]"LDAP://$strADSIF"
	$objSearcher = new-object System.DirectoryServices.DirectorySearcher 
	$objSearcher.SearchRoot = $strRoot
	$objSearcher.Filter = "(&(objectCategory=$strClassTypeF)(sAMAccountName=$strSAMNameF))"
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

function set-adsi ($strDomainF) {# sets the correct ADSI container for each domain
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
} # end set-adsi function

# ----------------------------#
# Start Script Execution Here #
# ----------------------------#

$strGroup = $args[0] # sAMAccount group name to search for
$strDomain = $args[1].ToLower()
$strInput = $args[2]

# if the Domain Name is not given, ask
if ($strDomain -eq "ap" -or $strDomain -eq "corp" -or $strDomain -eq "eu" -or $strDomain -eq "la" -or $strDomain -eq "meat" -or $strDomain -eq "na") {
	$strDomain = $args[1].ToLower()
}
else {
	$strDomain = Read-Host "What Domain is the group $strGroup in:`nAP, EU, LA, MEAT, NA"
}

$objInput = Import-Csv $args[2]

$strGroupADSI = set-adsi $strDomain # set the full ADSI path for the domain

$strClassType = "group"
$strGroupPath = get-dn $strGroup $strClassType $strGroupADSI # find the group

foreach ($objUser in $objInput) {
	$strClassType = "user"
	$strUserDomain = set-adsi $objUser.Domain
	$strUserName = [string]$objUser.UserName

	$strUserPath = get-dn $strUserName $strClassType $strUserDomain # find the user
		
	$strADSIUser = [ADSI]("$strUserPath")
	$strADSIGroup = [ADSI]("$strGroupPath")
	
	$objMemberCheck = ($strADSIGroup.member | where {$_ -eq $strADSIUser.distinguishedName})
		
	if ($objMemberCheck.length -gt 1) {
		Write-Output "User is already member of group.  No change made."
	}
	else
	{
	
		# adds the user to the group
		$strGroupMembers = $strADSIGroup.member
		$strADSIGroup.member = $strGroupMembers + $strADSIUser.distinguishedName
		$strADSIGroup.setinfo()
		$strUserDom = $objUser.Domain
		$strUsersAM = $strADSIUser.sAMAccountName
		$strGroupsAM =$strADSIGroup.sAMAccountName
		Write-Output "added $strUserDom `b`\ `b$strUsersAM to $strGroupsAM"
	}
}