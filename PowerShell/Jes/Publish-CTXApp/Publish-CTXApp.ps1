function Get-DN ($SAMNameF,$ClassTypeF,$LDAPPathF) { # function retuns the full CN of the user or group
	$ADSIRoot = [ADSI]("LDAP://$LDAPPathF")
	$ADSearch = new-object System.DirectoryServices.DirectorySearcher
	$ADSearch.SearchRoot = $ADSIRoot
	$ADSearch.Filter = "(&(objectCategory=$ClassTypeF)(sAMAccountName=$SAMNameF))"
	$FoundUsers = $ADSearch.findall()
	$FoundUsers[0].path
} # end Get-DN function

#Group Types
$strGlobalDist = "2"
$strDomainLocalDist = "4"
$strUniversalDist = "8"
$strGlobal = "-2147483646"
$strDomainLocal = "-2147483644"
$strUniversal = "-2147483640"

$ErrorActionPreference = "Continue"

$list = Import-Csv "apps.csv"
$data = @()

foreach ($item in $list) {
	if ($item.Domain -match "meat") {
		$OU = "ou=" + $item.Silo + ",ou=Terminal Servers,ou=MWTS,ou=ITSB,dc=meat,dc=cargill,dc=com"
		$dom = "dc=meat,dc=cargill,dc=com"
	}
	else {
		$OU = "ou=" + $item.Silo + ",ou=Terminal Servers,ou=MWTS,ou=ITSB,dc=" + $item.Domain + ",dc=corp,dc=cargill,dc=com"
		$dom = "dc=" + $item.Domain + ",dc=corp,dc=cargill,dc=com"
	}
	$objOU = [ADSI]("LDAP://$OU")
	$GroupName = ($item.Farm.ToLower() + "~" + $item.Silo.ToLower() + "~" + $item.AppName.ToLower()).Replace(" ","_")
	
	# Check for Groups
	$existW = Get-DN ($GroupName + "~w") "group" $dom
	$existA = Get-DN ($GroupName + "~a") "group" $dom

	# Create Groups if they do not exist
	if (!$existW) {
		$groupCN = "cn=" + $GroupName + "~w"
		$objCreate = $objOU.Create("group",$groupCN)
		$objCreate.Put("sAMAccountName",($GroupName + "~w"))
		$objCreate.Put("Description",$item.AppName)
		$objCreate.Put("groupType",$strGlobal)
		$objCreate.SetInfo()
	}
	else { Write-Host "Found:" $existW }
	if (!$existA) {
		$groupCN = "cn=" + $GroupName + "~a"
		$objCreate = $objOU.Create("group",$groupCN)
		$objCreate.Put("sAMAccountName",($GroupName + "~a"))
		$objCreate.Put("Description",($item.AppName + " Approvers"))
		$objCreate.Put("groupType",$strGlobal)
		$objCreate.SetInfo()
	}
	else { Write-Host "Found:" $existW }
}

$data | ft -Auto