# Update-Miami.ps1

$searcher = New-Object directoryservices.directorysearcher
$filter="(&(&(objectCategory=person)(objectClass=user)(l=Miami)(department=manufacturing)))"
$searcher.filter=$filter

$results=$searcher.findall() 

$results | foreach {
  [ADSI]$user="LDAP://"+ $_.properties.distinguishedname
  Write-Host  "Updating" $user.name
  $user.manager="CN=Tamara Nguyen,OU=Executive,OU=Employees,DC=MyCompany,DC=local"
  $user.description="MIA MFG"
  $user.SetInfo()
}
