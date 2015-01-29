#Get-PasswordProperty.ps1

Function Get-PasswordProperty {
    Param ($sam=$(throw "you must enter a sAMAccountname"))
    
    Function Get-UserDN {
        Param ($sam=$(throw "you must enter a sAMAccountname"))
        
        $searcher=New-Object DirectoryServices.DirectorySearcher
        $searcher.Filter="(&(objectcategory=person)(objectclass=user)(sAMAccountname="+$sam+"))"
    
        $user=$searcher.FindOne()
        
        if ($user.properties.name) {
            write $user
        } 
        else {
            write "NotFound"
        }
}
    
    Function Is-PasswordChangeAllowed {
        Param([string]$UserDN=$(Throw "You must specify a user's distinuished name path"))
        
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
    
    New-Variable ADS_UF_PASSWD_NOTREQD 0x0020 -Option Constant
    New-Variable ADS_UF_PASSWD_CANT_CHANGE 0x0040 -Option Constant
    New-Variable ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED 0x0080 -Option Constant
    New-Variable ADS_UF_DONT_EXPIRE_PASSWD 0x10000 -Option Constant
    New-Variable ADS_UF_SMARTCARD_REQUIRED 0x40000 -Option Constant
    New-Variable ADS_UF_PASSWD_EXPIRED 0x800000 -Option Constant
    
    $dn=Get-UserDN $sam
    
    #only run if user's distinguishedname was found
    if ($dn.path) {
        [ADSI]$user=$dn.path
        [int]$flag=$user.useraccountcontrol[0]
       
        #set default values
        $DoNotExpire=$False
        $PwdNotRequired=$False
        $PwdCantChange=$False
        $EncryptedTextPwdAllowed=$False
        $SmartCardRequired=$False
        $PwdExpired=$False
        
        if ($flag -band $ADS_UF_DONT_EXPIRE_PASSWD ) { $DoNotExpire=$True }
        if ($flag -band $ADS_UF_PASSWD_NOTREQD )     { $PwdNotRequired=$True }
        if ($flag -band $ADS_UF_PASSWD_CANT_CHANGE)  { $PwdCantChange=$True }
        if ($flag -band $ADS_UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED) { $EncryptedTextPwdAllowed=$True }
        if ($flag -band $ADS_UF_SMARTCARD_REQUIRED ) { $SmartCardRequired=$True }
        if ($flag -band $ADS_UF_PASSWD_EXPIRED ) { $PwdExpired=$True }
        if (!(Is-PasswordChangeAllowed $user.psbase.path)) { $PwdCantChange=$True } 
    
        $obj=New-Object PSObject
        $obj | Add-Member -MemberType NoteProperty -Name DN -Value $user.distinguishedname[0]
        $obj | Add-Member -MemberType NoteProperty -Name sAMAccountname -Value $sam
        $obj | Add-Member -MemberType NoteProperty -Name DoNotExpire -Value $DoNotExpire
        $obj | Add-Member -MemberType NoteProperty -Name NotRequired -Value $PwdNotRequired
        $obj | Add-Member -MemberType NoteProperty -Name NoChangeAllowed -Value $PwdCantChange
        $obj | Add-Member -MemberType NoteProperty -Name EncryptedAllowed -Value $EncryptedTextPwdAllowed
        $obj | Add-Member -MemberType NoteProperty -Name SmartCard -Value $SmartCardRequired
        $obj | Add-Member -MemberType NoteProperty -Name Expired -Value $PwdExpired
    
        write $obj
        
    }
    else {
        write "Failed to find $sam"
    }
}

#sample usage
# Get-PasswordProperty administrator

# "jeff","administrator","jfrost" | foreach {Get-PasswordProperty $_} | Format-Table samaccountname,DoNotExpire,NoChangeAllowed,EncryptedAllowed,Expired

# Get-QADUser -searchroot "OU=Employees,DC=Mycompany,DC=local" -enabled | 
# foreach {
#  Get-PasswordProperty $_.samaccountname
#   } | Export-Clixml "c:\allemployeepwd.xml"
