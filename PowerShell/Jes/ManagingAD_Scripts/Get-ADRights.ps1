# Get-ADRights.ps1

Function Get-ADRights {
   Param([string]$DN=$(Throw "You must specify the distinguished name of an Active Directory Object"))
     
    Function ConvertFrom-GUID {
        Param([string]$guid)
        # $guid will be like "f30e3bbe-9ff0-11d1-b603-0000f80367c1"
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
        
    [ADSI]$ADObject="LDAP://"+$DN
    
    #verify user exists
    if ($ADObject.distinguishedname) {  
        
        #Write-Host $ADObject.Distinguishedname -ForegroundColor Cyan
        
        [ADSI]$rootDSE="LDAP://RootDSE"

        #build hash table of extended rights
        $extRights=@{}
        [ADSI]$Extended="LDAP://CN=Extended-Rights,"+$rootDSE.ConfigurationNamingContext
        $Extended.psbase.children | foreach {
            $extRights.Add($_.DisplayName.toString(),$_.RightsGUID.toString().ToUpper())
             }
        $searcher=New-Object DirectoryServices.DirectorySearcher
        $searcher.searchroot="LDAP://CN=Schema,"+$rootDSE.ConfigurationNamingContext
       
        #get access rules for user object
        $rules=$adobject.psbase.objectsecurity.getAccessRules($True,$True,[system.security.principal.NTAccount])
        $rules | select IdentityReference,ActiveDirectoryRights,AccessControlType,ObjectType,`
        IsInherited,@{Name="ExtendedRight";Expression={
            $guid=$_.objectType.toString().ToUpper()
              If ($extRights.containsvalue($guid)) {
                ($extRights.GetEnumerator() | where {$_.value -match $guid}).name
            } Else {
                 $binary=ConvertFrom-GUID $guid
                 #search Schema for idGUID              
                 $searcher.filter="SchemaIDGUID=$binary" 
                 $searcher.findone() | foreach {$_.properties.name}
            } #end else
           } #end Expression
          } #end Name
        } #end if
    else {
         Write-Warning "$DN not found"
         } 
} #end function

#sample usage
# Get-ADRights "CN=COREAD,OU=Domain Controllers,DC=mycompany,DC=local"
# Get-ADRights "CN=Jack Frost,OU=Payroll,OU=Employees,DC=mycompany,DC=local" | Select IdentityReference,AccessControlType,ActiveDirectoryRights,ExtendedRight 
# Get-ADRights "CN=Jack Frost,OU=Payroll,OU=Employees,DC=mycompany,DC=local" | where {$_.IdentityReference -match "Self"} | select AccessControlType,ActiveDirectoryRights,ExtendedRight
# Get-ADRights "CN=Jack Frost,OU=Payroll,OU=Employees,DC=mycompany,DC=local" | where {$_.IdentityReference -match "IT Admins"} | Select IdentityReference,AccessControlType,ActiveDirectoryRights,IsInherited,ExtendedRight 
