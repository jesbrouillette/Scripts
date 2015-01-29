#Is-PasswordChangeAllowed.ps1

Function Is-PasswordChangeAllowed {
    Param([string]$UserDN=$(Throw "You must specify a user's distinguished name path"))
    
    $guid="ab721a53-1e2f-11d0-9819-00aa0040529b"
    
    [ADSI]$user=$UserDN
    
    if ($user.name) {
        $acl=$user.psbase.objectsecurity.getAccessrules($true,$true,[security.principal.NTAccount]) | `
        where {$_.IdentityReference -eq "NT Authority\SELF" -and $_.objecttype -eq $guid}
        
        if ($acl.AccessControlType -match "Allow") {
            write $true
        }
        else {
            write $False
        }

    }
    else {
        write "Failed to find $userDN"
    }

}

#sample usage
#  Is-PasswordChangeAllowed "LDAP://CN=jeff,cn=users,DC=mycompany,dc=local"
