# Get-ExtendedRightGUID.ps1

Function Get-ExtendedRightGUID {
    Param([string]$Right=$(Throw "You must enter an extended right name."))
    
    [ADSI]$rootDSE="LDAP://RootDSE"
    [ADSI]$Extended="LDAP://CN=Extended-Rights,"+$rootDSE.ConfigurationNamingContext

    $Extended.psbase.children | where {$_.Name -match $Right} | foreach {
      $guid=$_.RightsGUID }
    
    if (!$guid) {
    #search the schema if right now found in extended rights
     $searcher=New-Object DirectoryServices.DirectorySearcher  
     $searcher.searchroot="LDAP://CN=Schema,"+$rootDSE.ConfigurationNamingContext
     $searcher.filter="Name=$right"
     $searcher.FindOne() | foreach {
        [system.guid]$guid=$_.properties.schemaidguid[0] 
      }
    }
    
    write $guid.toString()    
}
