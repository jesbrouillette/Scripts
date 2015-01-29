#Add-ADPermission.ps1

Function Add-ADPermission {
    Param([string]$DN=$(Throw "You must specify the distinguished name of an Active Directory object."),
    [string]$SAM=$(Throw "You must specify the sAMAccountname of a user or group."),
    [string]$ADRights="ExtendedRight",
    [string]$right=$(Throw "You must specify the name of an extended or control access right"),
    [switch]$deny
    )
    
    Function Get-ExtendedRightGUID {
        Param([string]$Right=$(Throw "You must enter an extended right name."))
        
        [ADSI]$rootDSE="LDAP://RootDSE"
        [ADSI]$Extended="LDAP://CN=Extended-Rights,"+$rootDSE.ConfigurationNamingContext
        $Extended.psbase.children | where {$_.Name -match $Right} | foreach {
          $guid=$_.RightsGUID }
        
        if (!$guid) {
        #search the schema
         $searcher=New-Object DirectoryServices.DirectorySearcher  
         $searcher.searchroot="LDAP://CN=Schema,"+$rootDSE.ConfigurationNamingContext
         $searcher.filter="Name=$right"
         $searcher.FindOne() | foreach {
            [system.guid]$guid=$_.properties.schemaidguid[0] 
          }
        }
        
        write $guid.toString()
} 
    
   [ADSI]$ADObject="LDAP://"+$DN
    
    #default is to allow permission unless you specify the -deny switch
    if ($deny) {
        $permission="Deny"
    } 
    else {
        $permission="Allow"
    }

    #verify object exists
    if ($ADObject.distinguishedname) {  
        #get right GUID
    
        $account  = New-Object System.Security.Principal.NTAccount($sam)
        [System.DirectoryServices.ActiveDirectorySecurityInheritance]$inherit = "All"
    
        #add code to get this GUID from the control access right    
        $controlGUID = Get-ExtendedRightGUID $right
        
        if (!$controlGUID) {
            Write-Warning "Failed to find a GUID for $right"
            return
        }
        $msg="Setting {0} {1} rights on {2} property for {3} " -f $Permission,$ADRights,$right,$ADobject.distinguishedname[0]
        Write-Host $msg -ForegroundColor Cyan 
        
        #create an access rule object
        $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($account, $ADrights, $permission, $controlGUID, $Inherit)
        #add the rule to the Active Directory object
        $ADobject.psbase.get_objectSecurity().AddAccessRule($ace)
        $ADobject.psbase.CommitChanges()
    }
    
}

#sample usase
# Add-ADPermission -dn "CN=Roy Biv,OU=Executive,OU=Employees,DC=mycompany,DC=local" -sam "jhicks" -right "Send-As"
