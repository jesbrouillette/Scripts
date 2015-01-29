# Update-Company.ps1

$searcher = New-Object directoryservices.directorysearcher
$filter="(&(objectCategory=person)(objectClass=user))"
$searcher.filter=$filter

$results=$searcher.findall() 

$results | foreach {
  [ADSI]$user="LDAP://"+ $_.properties.distinguishedname
  Write-Host  "Updating" $user.name
  $user.company="MyCompany"
  $user.SetInfo()
}
