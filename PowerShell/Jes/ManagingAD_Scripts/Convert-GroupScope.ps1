#Convert-GroupScope.ps1

Function Convert-GroupScope {
    Param ([string]$name=$(Throw "You must enter a group name"),
    [string]$scope=$(Throw "You must enter a group scope: DomainLocal,Global or Universal")
    )

    Function Is-SecurityEnabled {
    #returns true if group type value indicates group is security enabled
        Param([int]$value=$(Throw "You forgot to specify a grouptype value"))
        
        New-Variable ADS_GROUP_TYPE_SECURITY_ENABLED 0x80000000 -option constant
        if ($value -band $ADS_GROUP_TYPE_SECURITY_ENABLED) {
            write $True }
        else {
            write $False
            }
    }

#main function body

    #validate scope
    if ($scope-notmatch "domainlocal" -and $scope -notmatch "global" -and $scope -notmatch "universal" ) {
        write "$scope is not a valid scope. Valid choices are DomainLocal,Global or Universal"
        Break    
    }
       
    $searcher=New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter="(&(objectclass=group)(cn=$name))"
    $result=$searcher.findone()
    
    if ($result) {
        [ADSI]$Group=$result.path
        $typeval=$Group.grouptype[0]
        if (Is-SecurityEnabled $typeval) {
            $security=$True
        }
        else {
            $security=$false
          }
          
        #find current group type  
          switch ($typeval) {
            {$typeval -band 2} {
                                $oldscope="global"
                                }
            {$typeval -band 4} {
                               $oldscope="domainlocal"
                                }
            {$typeval -band 8} {
                               $oldscope="universal"
                                }

            default {write "Failed to decode $typeval or illegal value"
                    $Failed=$True
                    }
          } #end switch
          
          if ($oldscope -match $scope) {
            write "The group $name is already at this scope:$scope"
            break
          }
          #bail if failed to decode group type
          if ($Failed) {break}
          
          Write-Host  "Changing $name scope ($oldscope) to $scope" -ForegroundColor Cyan
          
        #define a variable for each scope type
        Switch ($scope) {
        "domainlocal" {$scopeVal=4 }
        "global" {$scopeVal=2 }
        "universal" {$scopeVal=8}
        }
      
          #check if oldscope and new scope does not include universal
          #as long as beginning or end scope is set to universal you can change
          #it to anything
          if ($oldscope -notmatch "universal" -or $scope -notmatch "universal" ) {
              $Group.grouptype=8 #convert to Universal
              $Group.setinfo()
          }
          #now set group type to requested scope
              $Group.groupType=$scopeVal    
          
          #re-enable as security group if necessary
          if ($security) {
#           write "re-enabling as a security group"
             $group.groupType=$Group.grouptype[0] -bor 0x80000000 
          }
          #save new group type
           $Group.setinfo()
        } #end if ($result)
    else {
            write "Failed to find $name"

    } #end else


} #end function

#sample usage
# Convert-GroupScope "My Test Group" "global"
