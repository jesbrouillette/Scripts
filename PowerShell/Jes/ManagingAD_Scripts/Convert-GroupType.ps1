#Convert-GroupType.ps1

Function Convert-GroupType {
    Param ([string]$name=$(Throw "You must enter a group name"),
    [string]$type=$(Throw "You must enter a group type of either Security or Distribution")
    )
    
    New-Variable ADS_GROUP_TYPE_SECURITY_ENABLED 0x80000000 -option constant
    
    #validate type
    if ($type -notmatch "security" -and $type -notmatch "distribution") {
        write "$type is not recognized. Valid choices are Security or Distribution"
        Break    
    }
    
    $searcher=New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter="(&(objectclass=group)(cn=$name))"
    $result=$searcher.findone()
    
    if ($result) {
        [ADSI]$Group=$result.path
        $typeval=$Group.grouptype[0]
        
        switch ($type) {
            "security" {
                if ($typeval -band $ADS_GROUP_TYPE_SECURITY_ENABLED) {
                  write "Group $name is already security enabled" }
                  else {
                    write "security enabling"
                    $typeval=$typeval -bor $ADS_GROUP_TYPE_SECURITY_ENABLED
                    $Group.put("grouptype",$typeval)
                    $Group.setinfo()
                  }
             }
             
             "distribution" {
                 if (($typeval -band $ADS_GROUP_TYPE_SECURITY_ENABLED) -eq 0) {
                  write "Group $name is already a distribution list" 
                  }
                  else {
                    write "removing security flag"
                    $typeval=$typeval -bxor $ADS_GROUP_TYPE_SECURITY_ENABLED
                    $Group.put("grouptype",$typeval)
                    $Group.setinfo()
                    }
             }
        } #end switch
        
      } #end if
    
    else {
        write "Failed to find $name"
    }
    
}

#sample usage
# Convert-GroupType "My Test Group" security
