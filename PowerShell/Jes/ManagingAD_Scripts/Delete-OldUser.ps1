#Delete-OldUser.ps1

Function Get-PwdLastSetDate {

    Param([int64]$LastSet=0)
    if ($LastSet -eq 0) {
        write "Never Set or Re-Set"
    } else {
        [datetime]$utc="1/1/1601"
        $i=$LastSet/864000000000
        write ($utc.AddDays($i))
    }
}
    
Function Get-PwdAge {
    Param([int64]$LastSet=0)
    if ($LastSet -eq 0) {
        write "0"
    } else {
        [datetime]$ChangeDate=Get-PwdLastSetDate $LastSet
        [datetime]$RightNow=Get-Date
        
        write $RightNow.Subtract($ChangeDate).Days
    }
}

$cutoff=180
$ignore="Administrator","krbtgt","Jeffery Hicks"
$searcher = New-Object directoryservices.directorysearcher

#search user accounts with passwords that can expire
$searcher.filter="(&(&(objectCategory=person)(objectClass=user)"`
+"(!userAccountControl:1.2.840.113556.1.4.803:=65536)))"

$results=$searcher.findall()

$results | where {$ignore -notcontains ($_.properties.name)} | foreach {
    [int64]$last=($_.properties.pwdlastset)[0]
    if ((Get-PwdAge $last) -ge $cutoff) {
       [ADSI]$user="LDAP://"+ $_.properties.distinguishedname
       [ADSI]$Parent="LDAP://"+$user.psbase.parent.distinguishedName
       Write-Host "Deleting " $user.name "from" $Parent.name
#uncomment the next line to actually delete the user.
#        $Parent.delete("user","CN="+$user.name)
   }
}
