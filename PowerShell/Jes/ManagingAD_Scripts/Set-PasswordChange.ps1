#Set-PasswordChange.ps1

Function Set-PasswordChange {
    Param([string]$sam=$(Throw "You must specify a sAMAccountname"),
          [boolean]$Deny=$False
    )
    
    Function Get-UserDN {
        Param ([string]$sam=$(throw "you must enter a sAMAccountname"))
        
        $searcher=New-Object DirectoryServices.DirectorySearcher
        $searcher.Filter="(&(objectcategory=person)(objectclass=user)(sAMAccountname="+$sam+"))"
    
        $user=$searcher.FindOne()
        
        if ($user.name) {
            write $user
        } 
        else {
            write "NotFound"
        }
}

#get user object in AD based on SAMAccountname
    $dn=Get-UserDN $sam
    
    #only run if user distinguishedname  was found
    if ($dn.path) {
        [ADSI]$user=$dn.path
        
        $guid="ab721a53-1e2f-11d0-9819-00aa0040529b"
        
        $everyOne = [System.Security.Principal.SecurityIdentifier]"S-1-1-0"
        $self = [System.Security.Principal.SecurityIdentifier]"S-1-5-10"
        
        $EveryoneDeny = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($Everyone,"ExtendedRight","Deny",$guid)
        $EveryoneAllow = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($Everyone,"ExtendedRight","Allow",$guid)
  
        $SelfDeny = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($self,'ExtendedRight','Deny',$guid)
        $SelfAllow = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($self,'ExtendedRight','Allow',$guid)
        
        #Pick the right rules depending on whether $perm is set to Allow or Deny
        if ($Deny) {
            $SelfRule = $SelfDeny
            $EveryoneRule = $EveryoneDeny 
        }
        else 
        {
            $SelfRule = $SelfAllow
            $EveryoneRule = $EveryoneAllow
        }
        
        #The ModifyAccessRuleMethod requires an object to use for its output
        New-Variable r
        
        if (!($User.psbase.ObjectSecurity.ModifyAccessRule('Reset',$SelfRule,[ref]$r))) {
            Write-Host "Failed to modify access rule for SELF"
            Return
        }
        
        If (!($User.psbase.ObjectSecurity.ModifyAccessRule('Reset',$EveryoneRule,[ref]$r))) {
            Write-Host "Failed to modify access rule for EVERYONE"
            Return
        } 
        # changes were made so commit them
        $user.psbase.commitchanges()
    }
    else {
    write "Failed to find $sam"
    }

}

#sample usage
# Set-PasswordChange jfrost deny

