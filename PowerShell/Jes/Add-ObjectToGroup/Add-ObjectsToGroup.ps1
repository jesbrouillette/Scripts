# usage .\Add-Computer.ps1 "[groupname]" [domain] [list]
# must be run using a corp\mwts_ account

function GetDN ($strSAMNameF,$classF,$strADSIF) { # function retuns the full CN of the user or group
	$strRoot = [ADSI]"LDAP://$strADSIF"
	$objSearcher = new-object System.DirectoryServices.DirectorySearcher 
	$objSearcher.SearchRoot = $strRoot
	$objSearcher.Filter = "(&(objectCategory=$classF)(sAMAccountName=$strSAMNameF))"
	$objFound = $objSearcher.findall()

	if ($objFound.count -gt 1) {
		$intCount = 0
		foreach($object in $objFound) {
			write-output $intCount ": " $object.path
			$intCount = $intCount + 1
		}
		$strSelection = Read-Host "Please select item: "
		return $objFound[$strSelection].path
	}
	else {
		return $objFound[0].path
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

	$computerADSI = SetADSI $line.Domain
	$computerClass = $line.Class
	$computerName = [string]$line.Object

	$computerCN = GetDN $computerName $computerClass $computerADSI # find the computer
		
	$computerAD = [ADSI]("$computerCN")
	$groupAD = [ADSI]("$groupCN")
	
	$checkMembership = ($groupAD.member | where {$_ -eq $computerAD.distinguishedName})
		
	if ($checkMembership.length -gt 1) {
		Write-Output "Computer is already member of the group.  No change made."
	}
	else
	{
	
		# adds the user to the group
		$groupMembers = $groupAD.member
		$groupAD.member = $groupMembers + $computerAD.distinguishedName
		$groupAD.setinfo()
		$computerDom = $line.ComputerDom
		$computerSAM = $computerAD.sAMAccountName
		$groupSAM = $groupAD.sAMAccountName
		Write-Output "added $computerDom `b`\ `b$computerSAM to $groupSAM"
	}
}