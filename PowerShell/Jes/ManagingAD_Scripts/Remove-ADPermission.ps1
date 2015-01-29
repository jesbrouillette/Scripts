#Remove-ADPermission.ps1

Function Decode-RightsGUID {
    Param([string]$guid)
    
      Function ConvertFrom-GUID {
        Param([string]$guid)
        # $guid="f30e3bbe-9ff0-11d1-b603-0000f80367c1"
        $guid=$guid.Replace("-","")
        
        $a="\"+$guid.substring(6,2)+"\"+$guid.substring(4,2)+"\"+`
        $guid.substring(2,2)+"\"+$guid.substring(0,2)
        $b="\"+$guid.substring(10,2)+"\"+$guid.substring(8,2)+"\"+`
        $guid.substring(14,2)+"\"+$guid.substring(12,2)
        for ($i=16;$i -lt $guid.length ;$i+=2) {
            $c=$c+"\"+$guid.substring($i,2)    
        }
            write $a$b$c
    }
   
    [ADSI]$rootDSE="LDAP://RootDSE"
    
    $extRights=@{}
       
    [ADSI]$Extended="LDAP://CN=Extended-Rights,"+$rootDSE.ConfigurationNamingContext
    
    $Extended.psbase.children | foreach {
        $extRights.Add($_.DisplayName.toString(),$_.RightsGUID.toString().ToUpper())
     }
    
    If ($extRights.containsvalue($guid)) {
        $right=($extRights.GetEnumerator() | where {$_.value -match $guid}).name
    } Else {
        $searcher=New-Object DirectoryServices.DirectorySearcher
        $searcher.searchroot="LDAP://CN=Schema,"+$rootDSE.ConfigurationNamingContext
    
        $binary=ConvertFrom-GUID $guid
        $searcher.filter="SchemaIDGUID=$binary" 
        $right=$searcher.findone() | % {$_.properties.name}
    }
    write $right
}   
        
$identity="self"

[ADSI]$ADobject="LDAP://CN=Roy Biv,OU=Executive,OU=Employees,DC=mycompany,DC=local"

$rules=$adobject.psbase.objectsecurity.getAccessRules($True,$True,[system.security.principal.NTAccount])

$data = $rules | where {$_.IdentityReference -match $identity}

if ($data -is [object]) {
    $data | foreach {
        $_
        $guid = $_.objectType.toString().ToUpper()
        $right=Decode-RightsGUID $guid
        $rc=Read-Host "Do you want to delete the" $right "right [YN]?" 
        if ($rc -eq "y") {
            $ADobject.psbase.ObjectSecurity.RemoveAccessRule($data)
            $ADobject.psbase.commitchanges()
        }
  } #end ForEach
} #end $data -is [object]
