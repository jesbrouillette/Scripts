#Move-User.ps1

#log file
$log="movedusers.txt"

#accounts to ignore
$ignore="guest","krbtgt"

#OU to move to
$OU="LDAP://OU=Disabled Accounts,OU=Employees,DC=mycompany,DC=local"

#create directory searcher
$Searcher = New-Object DirectoryServices.DirectorySearcher

#find disabled accounts
$searcher.filter="(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))"

$results=$searcher.findall() 

$results | ForEach-Object {
      if ($ignore -notcontains ($_.properties.name)) {
        #get user object
        [ADSI]$user="LDAP://"+  $_.properties.distinguishedname
        
        $msg="{0} Moving: {1} to {2}"  -f (Get-Date -Format g),$user.distinguishedname,$OU
                
        #record event in log file
        write $msg | Out-File $log -append
        
        #move account
        $user.psbase.Moveto($OU)
      }
 }
 
 Write-Host "See $log for details"
