#Get-NestedMembership.ps1

Function Get-MemberOf {
    Param([string]$name=$(Throw "You must specify the distinguishedname of a user or group."),
          [Boolean]$expand=$False)
        
    [ADSI]$obj="LDAP://$name"
    
     if ($obj) {
         $Result=$obj.MemberOf
         
         if ($Result.count -ge 1) {  
            foreach ($item in $Result) {
                write $item
                 if ($expand) {
                 Get-MemberOf $item $expand
                 } 
             }
         }
       }
      else {
        Write-Warning "Failed to find $name"
      }
}

#sample usage
#Get-MemberOf "CN=Jack Frost,OU=Payroll,OU=Employees,DC=mycompany,DC=local" $True
