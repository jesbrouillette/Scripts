#New-ADGroup.ps1

Function New-ADGroup {
    Param([string]$name=$(Throw "You must specify a group name."),
    [string]$parent="OU=Groups,DC=mycompany,DC=Local",
    [string]$scope="Global",
    [boolean]$security=$True,
    [string]$description
    )
 
    [ADSI]$Container="LDAP://$parent"

    if (!$Container.distinguishedname) {
        Write-Error "Failed to find $parent"
        break
        }
    
    switch ($scope) {
        "domainlocal" {$grpType = 0x00000004}
        "global" {$grpType = 0x00000002}
        "universal" {$grpType = 0x00000008}
        default {Write-Error "Unknown group scope: $scope. Valid choices are DomainLocal,Global or Universal."
                $failed=$True
                }
    }
    
    if ($failed) {
        break
    }
    else {
        #modify group scope if it is security enabled
        if ($security) {
            $grpType=$grpType -bor 0x80000000
        }
        
        #create specified group
        $group=$Container.Create("group","CN=$name")
        $group.put("sAMAccountname",$name)
        $group.put("grouptype",$grpType)
        
        if ($description) {
            $group.put("description",$description)
        }
        
        $group.put("info","Created " + (Get-Date) + " by " + `
        $env:userdomain + "\"+ $env:username)
        $group.SetInfo()
    
    }

}

#sample usage
# New-ADGroup -name "RW IT Admins" -scope "domainlocal" -description "RW File Access"
