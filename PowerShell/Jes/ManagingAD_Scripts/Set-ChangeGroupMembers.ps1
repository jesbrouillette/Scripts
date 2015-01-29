#Set-ChangeGroupMembers.ps1

Function Set-ChangeGroupMembers {
    Param([string]$name=$(Throw "You must enter the distinguishedname of a group."),
          [boolean]$Allow=$True
    )
    [ADSI]$group="LDAP://"+$name
    
    if ($group.name) {
        if ($group.ManagedBy) {
        
        Function Get-DomainRoot {
        #for a given LDAP path, find the domain root flat name
            Param([string]$adspath)
            [ADSI]$obj=$adspath
            if ($obj.psbase.parent.name) {
                $parent=$obj.psbase.parent.name
                Get-DomainRoot ("LDAP://"+$obj.psbase.parent.distinguishedname)
            } 
            else {
                write $parent
            }
        }
               
          [ADSI]$ADUser="LDAP://"+$group.managedby
          $sam=$ADUser.samaccountname
          $domain=Get-DomainRoot $ADUser.psbase.path
          $User = New-Object System.Security.Principal.NTAccount($domain,$sam)
          $sid=$User.Translate([System.Security.Principal.SecurityIdentifier])
          #the GUID for the write member property
          $guid="bf9679c0-0de6-11d0-a285-00aa003049e2"    
          $mgr=[System.Security.Principal.SecurityIdentifier]$sid.value
          
          if ($Allow) {
            $Action="Allow"
            }
          else {
            $Action="Deny"
            }
            
          $mgrRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($mgr,"WriteProperty",$Action,$guid)
          
          New-Variable r
            
          If (!($group.psbase.ObjectSecurity.ModifyAccessRule('Reset',$mgrRule,[ref]$r))) {
             Write-Warning ("Failed to modify permission for "+ $group.managedby)
          }
          else {
                     
           # changes were successful so commit them
          $group.psbase.commitchanges()
          }
        }
        else {
        Write-Warning "No manager defined for $name"
        }
    } 
    else {
        Write-Warning "Failed to find $name"
    }

}

#sample usage
# Set-ChangeGroupMembers "CN=Payroll Staff,OU=Groups,DC=mycompany,dc=local" 
