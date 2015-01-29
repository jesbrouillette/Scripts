#Get-QADNestedMembership.ps1

Function Get-QADMemberOf {
    Param([string]$name=$(Throw "You must specify the name of a user or group."),
          [Boolean]$expand=$False
          )
    
    $Result=Get-QADObject $name | select MemberOf
    
    if ($Result.MemberOf.count -ge 1) {  
        foreach ($item in $Result.MemberOf) {
            write $item    
            if ($expand) {
                Get-QADMemberOf $item $expand
            } 
        }
    }
}

#sample usage
# Get-QADMemberOf jfrost $true
