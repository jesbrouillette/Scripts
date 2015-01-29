#Update-DisplayName.ps1

$searcher = New-Object directoryservices.directorysearcher
$filter="(&(objectCategory=person)(objectClass=user)(!displayname=*)(givenname=*)(sn=*))"
$searcher.filter=$filter

$results=$searcher.findall() 

$results | foreach {
  [ADSI]$user="LDAP://"+ $_.properties.distinguishedname
   Write-Host  "Updating" $user.name
  $display=$user.givenname.value + ' ' + $user.sn.value
  $user.Displayname=$display
  $user.SetInfo()
}
