param (
	[string]$Domain,
	[string]$User,
	[array]$Property,
	[switch]$Properties
)

#get-aduser.ps1

function GetUser ($Domain,$User) {

	# Set the proper DistinguisedName for the Domain
	if ($domain.ToLower() -eq "ap"){ $dc = "dc=ap,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "eu"){ $dc = "dc=eu,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "la"){ $dc = "dc=la,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "meat"){ $dc = "dc=meat,dc=cargill,dc=com"}
	elseif ($domain.ToLower() -eq "na"){ $dc = "dc=na,dc=corp,dc=cargill,dc=com" }
	elseif ($domain.ToLower() -eq "corp"){ $dc = "dc=corp,dc=cargill,dc=com" }
	else { $dc = $false }
	
	# Search for and return the first account matching $user
	if ($dc) {
		$AD = [ADSI]("LDAP://$DC")
		$search = new-object System.DirectoryServices.DirectorySearcher
		$search.SearchRoot = $AD
		$search.Filter = "(&(objectCategory=user)(sAMAccountName=$user))"
		$adUser = $search.FindOne()
		return $adUser
	}
	else { write-host $Domain"\"$User " was not found" ; return $false }
}

$path = GetUser $Domain $User
$userPath = $path.Path
$aDUser = [adsi]("$userPath")
$pNames = $aDUser.Properties.PropertyNames
if ($properties) { $pNames }
elseif ($Property) { 
	foreach ($item in $Property) {
		$row = "" | Select Property,Value
		$row.Property = $item
		$row.Value = [string]$aDUser.$item
		$row
	}
}
else {
	foreach ($item in $pNames) {
		$row = "" | Select Property,Value
		$row.Property = $item
		$row.Value = [string]$aDUser.$item
		$row
	}
}