function get-dn ($strSAMNameF,$strClassTypeF,$strADSIF) { # function retuns the full CN of the user or group
	$strRoot = [ADSI]"LDAP://$strADSIF"
	Write-Host `nSearching "LDAP://"`b$strADSIF "for the" $strClassTypeF $strSAMNameF`n
		$objSearcher = new-object System.DirectoryServices.DirectorySearcher 
	$objSearcher.SearchRoot = $strRoot
	$objSearcher.Filter = "(&(objectCategory=$strClassTypeF)(sAMAccountName= $strSAMNameF))"
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

$strSAMName = $args[0] # sAMAccount name to search for
$strClassType = $args[1] # type (group or user)

# if the Domain Name is not given, ask
if ($args[2] -eq "") {
	$strDomain = Read-Host "What Domain is the user in:`nAP`nEU`nLA`nMEAT`nNA"
}
else {
	$strDomain = $args[2]
}

# sets the correct ADSI container for each domain
if ($strDomain.ToLower() -eq "ap"){
	$strADSI = "dc=ap,dc=corp,dc=cargill,dc=com"
}
elseif ($strDomain.ToLower() -eq "corp"){
	$strADSI = "dc=corp,dc=cargill,dc=com"
}
elseif ($strDomain.ToLower() -eq "eu"){
	$strADSI = "dc=eu,dc=corp,dc=cargill,dc=com"
}
elseif ($strDomain.ToLower() -eq "la"){
	$strADSI = "dc=la,dc=corp,dc=cargill,dc=com"
}
elseif ($strDomain.ToLower() -eq "meat"){
	$strADSI = "dc=meat,dc=cargill,dc=com"
}
elseif ($strDomain.ToLower() -eq "na"){
	$strADSI = "dc=na,dc=corp,dc=cargill,dc=com"
}
else {
	Write-Output "Domain information is incorrect"
	exit
}

$strPath = get-dn $strSAMName $strClassType $strADSI

if ($strPath -ne $null) {
	$strPath
}
else {
	$strDomain = $strDomain.ToUpper()
	Write-Output "Could not find the $strClassType $strSAMNAME in the $strDomain domain"
}
