#New-ComputerAccount.ps1

New-Variable UF_WORKSTATION_TRUST_ACCOUNT 0x1000 -option Constant
New-Variable UF_ACCOUNTDISABLE  0x2 -option Constant

$UAC = $UF_WORKSTATION_TRUST_ACCOUNT 
#if you want the computer acccount to be disabled use this
# $UAC = $UF_WORKSTATION_TRUST_ACCOUNT -bor $UF_ACCOUNTDISABLE

#Name must be UPPERCASE and 15 or less characters
$name="TESTSERVER3"

[ADSI]$OU="LDAP://OU=Servers,DC=mycompany,DC=local"

$newcomputer=$OU.create("computer","CN=$name")
$newcomputer.put("samaccountname",$name+"$")
$newcomputer.put("userAccountControl", $UAC)
$newcomputer.setinfo()
$newcomputer.setpassword($name.ToLower()+"$")
$newcomputer.put("Description","Test Server")
$newcomputer.setinfo()
