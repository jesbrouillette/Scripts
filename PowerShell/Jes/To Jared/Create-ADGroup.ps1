#Group Types
$strGlobalDist = "2"
$strDomainLocalDist = "4"
$strUniversalDist = "8"
$strGlobal = "-2147483646"
$strDomainLocal = "-2147483644"
$strUniversal = "-2147483640"

$objGroups = Import-Csv $args[0]
$strLDAPath = "LDAP://" + $args[1]
$objOU = [ADSI]($strLDAPath)

foreach ($objGroup in $objGroups) {
	$objCreate = $objOU.Create("group","cn=" + $objGroup.Group)
	$objCreate.Put("sAMAccountName",$objGroup.Group)
	$objCreate.Put("Description",$objGroup.Share)
	$objCreate.Put("groupType",$strDomainLocal)
	foreach ($objMember in $objGroup.Members) {
		$objCreate.Put("User",$objMember)
	}
	$objCreate.SetInfo()
}