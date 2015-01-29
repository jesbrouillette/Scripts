#Group Types
$strGlobalDist = "2"
$strDomainLocalDist = "4"
$strUniversalDist = "8"
$strGlobal = "-2147483646"
$strDomainLocal = "-2147483644"
$strUniversal = "-2147483640"

$objGroups = Import-Csv $args[0]
$objOU = [ADSI]("LDAP://ou=Users,ou=Minneapolis,ou=Flour,ou=NAFI,dc=na,dc=corp,dc=cargill,dc=com")

foreach ($objGroup in $objGroups) {
	$objCreate = $objOU.Create("group","cn=" + $objGroup.Group + ",ou=Users,ou=Minneapolis,ou=Flour,ou=NAFI,dc=na,dc=corp,dc=cargill,dc=com")
	$objCreate.Put("sAMAccountName",$objGroup.Group)
	$objCreate.Put("Description",$objGroup.Share)
	$objCreate.Put("groupType",$strDomainLocal)
	$objCreate.SetInfo()
}